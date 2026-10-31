import assert from "node:assert/strict";
import { chmod, copyFile, mkdtemp, readFile, readdir, rm, writeFile, mkdir, stat, symlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as sleep } from "node:timers/promises";
import test from "node:test";
import * as NodeServices from "@effect/platform-node/NodeServices";
import { Cause, Effect, Exit, Layer, ManagedRuntime } from "effect";
import {
  CustomEditor, discoverAndLoadExtensions, ExtensionRunner, ModelRegistry, ModelRuntime, SessionManager,
  type ExtensionUIContext,
} from "@earendil-works/pi-coding-agent";
import { TuiAltScreen, visibleWidth, type EditorTheme, type Terminal } from "@earendil-works/pi-tui";
// Pi only exports this class as a type; use the installed implementation in this host integration test.
import { KeybindingsManager } from "../node_modules/@earendil-works/pi-coding-agent/dist/core/keybindings.js";
import * as Config from "../src/config.ts";
import * as HerdrPane from "../src/herdr-pane.ts";
import * as SplitEditing from "../src/split-editing.ts";

const fixtures = join(dirname(fileURLToPath(import.meta.url)), "fixtures");
async function setup() {
  const root = await mkdtemp(join(tmpdir(), "herdr-editor ' test-"));
  const old = { ...process.env };
  const extensionDir = join(root, "agent", "extensions", "herdr-split-editor");
  await mkdir(dirname(extensionDir), { recursive: true });
  await symlink(join(fixtures, "..", ".."), extensionDir, "dir");
  await copyFile(join(fixtures, "herdr.mjs"), join(root, "herdr"));
  await chmod(join(root, "herdr"), 0o700);
  Object.assign(process.env, {
    PATH: `${root}:${process.env.PATH}`, TEST_HERDR_DIR: root, TMPDIR: root,
    HERDR_ENV: "1", HERDR_PANE_ID: "opaque:caller", PI_CODING_AGENT_DIR: join(root, "agent"),
  });
  for (const key of Object.keys(process.env)) {
    if (key.startsWith("SPLIT_EDITOR_") || key.startsWith("TEST_EDITOR_") || (key.startsWith("TEST_HERDR_") && key !== "TEST_HERDR_DIR")) delete process.env[key];
  }
  const runtime = ManagedRuntime.make(SplitEditing.layerWithoutDependencies.pipe(
    Layer.provide(HerdrPane.layerWithoutDependencies(process.env.SHELL)),
    Layer.provideMerge(NodeServices.layer),
  ));
  const config = await Effect.runPromise(Config.parse({ editor: `${process.execPath} '${join(fixtures, "editor.mjs")}'` }));
  const calls = async (): Promise<ReadonlyArray<ReadonlyArray<string>>> => JSON.parse(`[${(await readFile(join(root, "calls.jsonl"), "utf8")).trim().split("\n").join(",")}]`);
  return {
    root, runtime, config, calls,
    async close() {
      await runtime.dispose();
      for (const key of Object.keys(process.env)) if (!(key in old)) delete process.env[key];
      Object.assign(process.env, old);
      await rm(root, { recursive: true, force: true });
    },
  };
}

async function waitFor(predicate: () => Promise<boolean>) {
  const deadline = Date.now() + 5000;
  while (!(await predicate())) {
    assert.ok(Date.now() < deadline, "condition timed out");
    await sleep(20);
  }
}

async function waitForEditor(root: string) {
  let file: string | undefined;
  await waitFor(async () => {
    const directory = (await readdir(root)).find((name) => name.startsWith("pi-herdr-split-editor-"));
    if (directory === undefined || !(await readdir(join(root, directory))).includes("status.started")) return false;
    file = join(root, directory, "prompt.md");
    return true;
  });
  assert.ok(file);
  return file;
}

test("unsupported shell launch mode retains the prompt and never types a fallback command", async () => {
  const h = await setup();
  try {
    process.env.TEST_HERDR_IGNORE_SHELL = "1";
    let recovery = "";
    const result = await h.runtime.runPromiseExit(Effect.flatMap(SplitEditing.Service, (service) => service.edit({ cwd: h.root, text: "recover me", config: h.config, onPrepared: (file) => { recovery = file; } })));
    assert.ok(Exit.isFailure(result));
    assert.match(Cause.pretty(result.cause), /shell_mode must be auto/);
    assert.equal(await readFile(recovery, "utf8"), "recover me");
    const commands = await h.calls();
    assert.equal(commands.some((args) => args[1] === "run" || args[1] === "send-text" || args[1] === "send-keys"), false);
    assert.deepEqual(commands.filter((args) => args[1] === "close"), [["pane", "close", "opaque:editor-7"]]);
  } finally { await h.close(); }
});

test("a pane that closes before startup fails without claiming to have edited the prompt", async () => {
  const h = await setup();
  try {
    process.env.TEST_HERDR_CLOSE_BEFORE_START = "1";
    let recovery = "";
    const result = await h.runtime.runPromiseExit(Effect.flatMap(SplitEditing.Service, (service) => service.edit({ cwd: h.root, text: "draft", config: h.config, onPrepared: (file) => { recovery = file; } })));
    assert.ok(Exit.isFailure(result));
    assert.match(Cause.pretty(result.cause), /closed before the editor started/);
    assert.equal(await readFile(recovery, "utf8"), "draft");
  } finally { await h.close(); }
});

test("manual pane closure reads the last saved file instead of waiting forever", async () => {
  const h = await setup();
  try {
    process.env.TEST_EDITOR_DELAY = "60000";
    const pending = h.runtime.runPromise(Effect.flatMap(SplitEditing.Service, (service) => service.edit({ cwd: h.root, text: "original", config: h.config, onPrepared: () => {} })));
    const file = await waitForEditor(h.root);
    await writeFile(file, "last saved\n");
    const state = JSON.parse(await readFile(join(h.root, "state.json"), "utf8"));
    process.kill(-state.pid, "SIGKILL");
    await writeFile(join(h.root, "state.json"), JSON.stringify({ ...state, closed: true }));
    const result = await pending;
    assert.equal(result.text, "last saved");
    assert.match(result.warnings.join("\n"), /without exit status/);
    await h.runtime.runPromise(result.discardRecovery);
  } finally { await h.close(); }
});

test("a polling failure is not mistaken for pane closure and still cleans up the owned pane", async () => {
  const h = await setup();
  try {
    process.env.TEST_HERDR_FAIL = "get";
    process.env.TEST_EDITOR_DELAY = "60000";
    let recovery = "";
    const result = await h.runtime.runPromiseExit(Effect.flatMap(SplitEditing.Service, (service) => service.edit({ cwd: h.root, text: "draft", config: h.config, onPrepared: (file) => { recovery = file; } })));
    assert.ok(Exit.isFailure(result));
    assert.match(Cause.pretty(result.cause), /Cannot inspect editor/);
    assert.equal(await readFile(recovery, "utf8"), "draft");
    assert.deepEqual((await h.calls()).filter((args) => args[1] === "close"), [["pane", "close", "opaque:editor-7"]]);
  } finally { await h.close(); }
});

test("configuration precedence, reloads, and project trust apply to executable options", async () => {
  const h = await setup();
  try {
    const agent = join(h.root, "agent");
    const cwd = join(h.root, "project");
    await mkdir(join(cwd, ".pi"), { recursive: true });
    await writeFile(join(agent, "extensions", "split-editor.json"), JSON.stringify({ editor: "global", size: "60%", direction: "v" }));
    await writeFile(join(agent, "settings.json"), JSON.stringify({ externalEditor: "ignored", splitEditor: { editor: "global settings", size: "40%" } }));
    await writeFile(join(cwd, ".pi", "split-editor.json"), JSON.stringify({ editor: "project", showIndicator: false }));
    await writeFile(join(cwd, ".pi", "settings.json"), JSON.stringify({ splitEditor: { editor: "project settings", size: "30%" } }));
    const config = await h.runtime.runPromise(Config.load(agent, cwd, { SPLIT_EDITOR_EDITOR: "env editor", SPLIT_EDITOR_SHOW_INDICATOR: "YES" }, "trusted"));
    assert.deepEqual(config, { editor: "env editor", size: "30%", direction: "down", showIndicator: true });
    await writeFile(join(cwd, ".pi", "settings.json"), JSON.stringify({ splitEditor: { editor: "changed" } }));
    assert.equal((await h.runtime.runPromise(Config.load(agent, cwd, {}, "trusted"))).editor, "changed");
    await writeFile(join(cwd, ".pi", "split-editor.json"), "malformed untrusted config");
    assert.equal((await h.runtime.runPromise(Config.load(agent, cwd, {}, "untrusted"))).editor, "global settings");
  } finally { await h.close(); }
});

test("malformed configuration is reported at the loading boundary", async () => {
  const h = await setup();
  try {
    // Keep the trailing-newline regression, not a matrix of Schema's built-in validators.
    const invalid = await h.runtime.runPromiseExit(Config.load(h.root, h.root, { SPLIT_EDITOR_EDITOR: "nvim\n" }));
    assert.ok(Exit.isFailure(invalid));
    assert.match(Cause.pretty(invalid.cause), /Invalid split-editor options/);
    await writeFile(join(h.root, "settings.json"), "{");
    const malformed = await h.runtime.runPromiseExit(Config.load(h.root, h.root, {}));
    assert.ok(Exit.isFailure(malformed));
    assert.match(Cause.pretty(malformed.cause), /Invalid splitEditor settings/);
  } finally { await h.close(); }
});

async function createPiHarness(root: string, mode: "tui" | "rpc" = "tui") {
  // Exercise standard extensions-directory discovery, without an explicit file/settings entry.
  const loaded = await discoverAndLoadExtensions([], root, join(root, "agent"));
  assert.deepEqual(loaded.errors, []);
  assert.equal(loaded.extensions.length, 1);
  const models = await ModelRuntime.create({ authPath: join(root, "auth.json"), modelsPath: null, modelsStorePath: join(root, "models-store.json"), refreshOnCreate: false });
  const runner = new ExtensionRunner(loaded.extensions, loaded.runtime, root, SessionManager.inMemory(root), new ModelRegistry(models));
  const errors: string[] = [];
  runner.onError((error) => errors.push(error.error));
  const notifications: string[] = [];
  let factory: Parameters<ExtensionUIContext["setEditorComponent"]>[0];
  runner.setUIContext({
    ...runner.getUIContext(),
    notify: (message) => { notifications.push(message); },
    setEditorComponent: (next) => { factory = next; },
  }, mode);
  const terminal: Terminal = {
    columns: 80, rows: 40, kittyProtocolActive: false,
    start() {}, stop() {}, async drainInput() {}, write() {}, moveBy() {},
    hideCursor() {}, showCursor() {}, clearLine() {}, clearFromCursor() {},
    clearScreen() {}, setTitle() {}, setProgress() {}, setProgramStatus() {},
  };
  const tui = new TuiAltScreen(terminal);
  const identity = (text: string) => text;
  const theme: EditorTheme = { borderColor: identity, selectList: {
    selectedPrefix: identity, selectedText: identity, description: identity, scrollInfo: identity, noMatch: identity,
  } };
  await runner.emit({ type: "session_start", reason: "startup" });
  const bindings = new KeybindingsManager({ "app.editor.external": "ctrl+g", "app.interrupt": "escape", "app.clear": "ctrl+c" });
  let editor = factory?.(tui, theme, bindings);
  return {
    editor, notifications,
    recreateEditor() {
      const replacement = factory?.(tui, theme, bindings);
      replacement?.setText(editor?.getText() ?? "");
      editor = replacement;
      return replacement;
    },
    async close() {
      await runner.emit({ type: "session_shutdown", reason: "quit" });
      tui.stop();
      assert.deepEqual(errors, []);
    },
  };
}

test("Pi round-trips saved text through a private, directly launched editor even after a nonzero exit", async () => {
  const h = await setup();
  process.env.SPLIT_EDITOR_EDITOR = h.config.editor;
  process.env.SPLIT_EDITOR_SIZE = "30%";
  process.env.SPLIT_EDITOR_DIRECTION = "down";
  process.env.SHELL = "/some user's/shell";
  process.env.TEST_EDITOR_REPORT_SHELL = join(h.root, "editor-shell.json");
  process.env.TEST_EDITOR_DELAY = "400";
  process.env.TEST_EDITOR_EXIT = "17";
  const pi = await createPiHarness(h.root);
  try {
    assert.ok(pi.editor instanceof CustomEditor);
    const editor = pi.editor;
    editor.setText("draft ' $HOME\n");
    editor.handleInput("\x07");
    editor.handleInput("\x07");
    editor.handleInput("ignored");
    editor.handleInput("\r");
    assert.equal(editor.getText(), "draft ' $HOME\n");
    for (const width of [1, 18, 80]) {
      for (const line of editor.render(width)) assert.ok(visibleWidth(line) <= width, `render overflow at ${width}`);
    }
    const file = await waitForEditor(h.root);
    const script = join(dirname(file), "status.sh");
    assert.equal((await stat(file)).mode & 0o777, 0o600);
    assert.equal((await stat(dirname(file))).mode & 0o777, 0o700);
    assert.equal((await stat(script)).mode & 0o777, 0o700);
    await waitFor(async () => editor.getText() === "draft ' $HOME\n\n한글 edited");
    await waitFor(async () => !(await readdir(h.root)).some((name) => name.startsWith("pi-herdr-split-editor-")));
    assert.deepEqual(JSON.parse(await readFile(join(h.root, "editor-shell.json"), "utf8")), { shell: process.env.SHELL });
    const commands = await h.calls();
    assert.deepEqual(commands.filter((args) => args[1] === "split"), [["pane", "split", "--current", "--direction", "down", "--ratio", "0.7", "--cwd", h.root, "--env", `SHELL=${script}`, "--focus"]]);
    assert.deepEqual(commands.filter((args) => args[1] === "close"), [["pane", "close", "opaque:editor-7"]]);
    assert.equal(pi.notifications[0], "Split editor is already open");
    assert.match(pi.notifications[1] ?? "", /status 17/);
    editor.handleInput("!");
    assert.equal(editor.getText(), "draft ' $HOME\n\n한글 edited!");
  } finally { await pi.close(); await h.close(); }
});

test("Pi falls back outside Herdr and refuses missing caller context", async () => {
  const h = await setup();
  const pi = await createPiHarness(h.root);
  try {
    assert.ok(pi.editor instanceof CustomEditor);
    let fallback = false;
    pi.editor.onAction("app.editor.external", () => { fallback = true; });
    delete process.env.HERDR_ENV;
    pi.editor.handleInput("\x07");
    assert.equal(fallback, true);
    process.env.HERDR_ENV = "1";
    delete process.env.HERDR_PANE_ID;
    pi.editor.handleInput("\x07");
    assert.match(pi.notifications.join("\n"), /caller pane is missing/);
    await assert.rejects(readFile(join(h.root, "calls.jsonl")), { code: "ENOENT" });
  } finally { await pi.close(); await h.close(); }
});

test("Pi does not overwrite a programmatically replaced prompt", async () => {
  const h = await setup();
  process.env.SPLIT_EDITOR_EDITOR = h.config.editor;
  process.env.TEST_EDITOR_DELAY = "400";
  const pi = await createPiHarness(h.root);
  try {
    assert.ok(pi.editor instanceof CustomEditor);
    pi.editor.setText("original");
    pi.editor.handleInput("\x07");
    pi.editor.setText("replacement from another extension");
    await waitFor(async () => pi.notifications.some((message) => message.includes("Prompt changed while editing")));
    assert.equal(pi.editor.getText(), "replacement from another extension");
    const directory = (await readdir(h.root)).find((name) => name.startsWith("pi-herdr-split-editor-"));
    assert.ok(directory);
    assert.equal(await readFile(join(h.root, directory, "prompt.md"), "utf8"), "original\n한글 edited\n");
  } finally { await pi.close(); await h.close(); }
});

test("Pi cancellation during pane acquisition closes the returned pane and unlocks the unchanged prompt", async () => {
  const h = await setup();
  process.env.SPLIT_EDITOR_EDITOR = h.config.editor;
  process.env.TEST_EDITOR_DELAY = "60000";
  process.env.TEST_HERDR_DELAY = "split";
  const pi = await createPiHarness(h.root);
  try {
    assert.ok(pi.editor instanceof CustomEditor);
    const editor = pi.editor;
    editor.setText("cancel this edit, not the prompt");
    editor.handleInput("\x07");
    await waitFor(async () => (await h.calls().catch(() => [])).some((args) => args[1] === "split"));
    editor.handleInput("\x03");
    await waitFor(async () => pi.notifications.some((message) => message.includes("Split edit interrupted")));
    assert.equal(JSON.parse(await readFile(join(h.root, "state.json"), "utf8")).closed, true);
    assert.equal(editor.getText(), "cancel this edit, not the prompt");
    editor.handleInput("!");
    assert.equal(editor.getText(), "cancel this edit, not the prompt!");
  } finally { await pi.close(); await h.close(); }
});

test("Pi shutdown awaits retired editor cleanup and retains its recoverable draft", async () => {
  const h = await setup();
  process.env.SPLIT_EDITOR_EDITOR = h.config.editor;
  process.env.TEST_EDITOR_DELAY = "60000";
  process.env.TEST_HERDR_DELAY = "close";
  const pi = await createPiHarness(h.root);
  try {
    assert.ok(pi.editor instanceof CustomEditor);
    pi.editor.setText("do not lose this");
    pi.editor.handleInput("\x07");
    const file = await waitForEditor(h.root);
    pi.recreateEditor();
    pi.recreateEditor();
    await pi.close();
    assert.equal(JSON.parse(await readFile(join(h.root, "state.json"), "utf8")).closed, true);
    assert.equal(await readFile(file, "utf8"), "do not lose this");
    assert.ok(pi.notifications.some((message) => message.includes(`Saved prompt: ${file}`)));
  } finally { await pi.close(); await h.close(); }
});

test("a replacement editor waits for the previous pane to close before opening another", async () => {
  const h = await setup();
  process.env.SPLIT_EDITOR_EDITOR = h.config.editor;
  process.env.TEST_EDITOR_DELAY = "60000";
  process.env.TEST_HERDR_DELAY = "close";
  const pi = await createPiHarness(h.root);
  try {
    assert.ok(pi.editor instanceof CustomEditor);
    pi.editor.setText("draft");
    pi.editor.handleInput("\x07");
    await waitForEditor(h.root);
    const replacement = pi.recreateEditor();
    assert.ok(replacement instanceof CustomEditor);
    process.env.TEST_EDITOR_DELAY = "0";
    replacement.handleInput("\x07");
    await waitFor(async () => replacement.getText() === "draft\n한글 edited");
    const commands = await h.calls();
    assert.equal(commands.filter((args) => args[1] === "split").length, 2);
    assert.ok(commands.findIndex((args) => args[1] === "close") < commands.findLastIndex((args) => args[1] === "split"));
  } finally { await pi.close(); await h.close(); }
});

test("Pi installs no terminal component in RPC mode", async () => {
  const h = await setup();
  const pi = await createPiHarness(h.root, "rpc");
  try {
    assert.equal(pi.editor, undefined);
    await assert.rejects(readFile(join(h.root, "calls.jsonl")), { code: "ENOENT" });
  } finally { await pi.close(); await h.close(); }
});
