#!/usr/bin/env node
// A local terminal-provider substitute: exercises real CLI processes and shell wrappers.
import { appendFileSync, existsSync, readFileSync, writeFileSync } from "node:fs";
import { spawn } from "node:child_process";
import { setTimeout } from "node:timers/promises";

const root = process.env.TEST_HERDR_DIR;
if (!root) process.exit(2);
const args = process.argv.slice(2);
appendFileSync(`${root}/calls.jsonl`, `${JSON.stringify(args)}\n`);
const statePath = `${root}/state.json`;
const state = existsSync(statePath) ? JSON.parse(readFileSync(statePath, "utf8")) : { closed: false };
const action = args[1];
function fail(code) {
  console.error(JSON.stringify({ error: { code, message: "test failure" } }));
  process.exit(1);
}
function reply(result) { console.log(JSON.stringify({ result })); }
if (process.env.TEST_HERDR_FAIL === action) fail("test_rejected");
if (process.env.TEST_HERDR_DELAY === action) await setTimeout(300);
if (action === "split") {
  if (process.env.TEST_HERDR_CLOSE_BEFORE_START === "1") {
    writeFileSync(statePath, JSON.stringify({ closed: true }));
    reply({ pane: { pane_id: "opaque:editor-7" } });
    process.exit(0);
  }
  const env = { ...process.env };
  for (let index = 0; index < args.length; index++) {
    if (args[index] !== "--env") continue;
    const entry = args[++index];
    const separator = entry.indexOf("=");
    env[entry.slice(0, separator)] = entry.slice(separator + 1);
  }
  if (!env.SHELL) fail("missing_shell_override");
  const child = process.env.TEST_HERDR_IGNORE_SHELL === "1"
    ? spawn("/bin/sh", ["-c", "sleep 60"], { detached: true, stdio: "ignore", env })
    : spawn(env.SHELL, [], { detached: true, stdio: "ignore", env });
  child.on("error", () => fail("pane_split_failed"));
  await new Promise((resolve) => child.once("spawn", resolve));
  child.unref();
  writeFileSync(statePath, JSON.stringify({ closed: false, pid: child.pid }));
  reply({ pane: { pane_id: "opaque:editor-7" } });
} else if (action === "get") {
  if (state.closed) fail("pane_not_found");
  reply({ pane: { pane_id: "opaque:editor-7" } });
} else if (action === "close") {
  if (state.closed) fail("pane_not_found");
  if (state.pid) {
    try { process.kill(-state.pid, "SIGKILL"); }
    catch (error) { if (error.code !== "ESRCH") throw error; }
  }
  writeFileSync(statePath, JSON.stringify({ ...state, closed: true }));
  reply({ type: "pane_closed" });
} else process.exit(2);
