import {
  CustomEditor, getAgentDir,
  type ExtensionAPI, type ExtensionUIContext, type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, type EditorTheme, type TUI } from "@earendil-works/pi-tui";
import * as NodeServices from "@effect/platform-node/NodeServices";
import { Cause, Effect, Exit, Layer, ManagedRuntime } from "effect";
import * as Config from "./config.ts";
import * as HerdrPane from "./herdr-pane.ts";
import * as SplitEditing from "./split-editing.ts";

const layer = (originalShell: string | undefined) => SplitEditing.layerWithoutDependencies.pipe(
  Layer.provide(HerdrPane.layerWithoutDependencies(originalShell)),
  Layer.provideMerge(NodeServices.layer),
);
type Runtime = ManagedRuntime.ManagedRuntime<SplitEditing.Service | NodeServices.NodeServices, never>;
type Editing = { readonly controller: AbortController; recoveryFile: string | undefined };

class SplitEditor extends CustomEditor {
  private editing: Editing | undefined;
  private pending: Promise<void> = Promise.resolve();
  private active = true;
  private showIndicator = true;

  constructor(
    tui: TUI,
    theme: EditorTheme,
    private readonly bindings: KeybindingsManager,
    private readonly ui: ExtensionUIContext,
    private readonly cwd: string,
    private readonly runtime: Runtime,
    private readonly projectTrust: () => "trusted" | "untrusted",
    private readonly ready: Promise<void>,
  ) {
    super(tui, theme, bindings, { embedWorkingStatus: true });
  }

  override handleInput(data: string): void {
    if (!this.active) return;
    if (this.bindings.matches(data, "app.editor.external")) {
      if (this.editing !== undefined) {
        this.ui.notify("Split editor is already open", "warning");
        return;
      }
      if (process.env.HERDR_ENV !== "1") {
        // Preserve Pi's configured blocking editor outside Herdr, without touching any session.
        super.handleInput(data);
        return;
      }
      if (!process.env.HERDR_PANE_ID) {
        this.ui.notify("Herdr caller pane is missing; refusing to split the focused pane", "error");
        return;
      }
      const operation: Editing = { controller: new AbortController(), recoveryFile: undefined };
      this.editing = operation;
      this.tui.requestRender();
      this.pending = this.open(operation);
      return;
    }
    if (this.editing !== undefined) {
      if (this.bindings.matches(data, "app.interrupt") || this.bindings.matches(data, "app.clear")) {
        this.editing.controller.abort();
      }
      return;
    }
    super.handleInput(data);
  }

  override render(width: number): string[] {
    const lines = super.render(width).map((line) => truncateToWidth(line, Math.max(0, width), ""));
    if (this.editing === undefined || !this.showIndicator) return lines;
    const last = lines.length - 1;
    const border = lines[last];
    const label = " SPLIT EDITOR OPEN ";
    if (border !== undefined && width >= visibleWidth(label)) {
      lines[last] = truncateToWidth(border, width - visibleWidth(label), "") + label;
    }
    return lines;
  }

  async stop(): Promise<void> {
    this.active = false;
    this.editing?.controller.abort();
    await this.pending;
  }

  private async open(operation: Editing): Promise<void> {
    const original = this.getExpandedText();
    try {
      // Appearance changes can replace this component before the previous pane has closed.
      await this.ready;
      if (operation.controller.signal.aborted) return;
      const result = await this.runtime.runPromiseExit(Effect.gen({ self: this }, function* () {
        const config = yield* Config.load(getAgentDir(), this.cwd, { ...process.env }, this.projectTrust());
        this.showIndicator = config.showIndicator;
        this.tui.requestRender();
        const editing = yield* SplitEditing.Service;
        return yield* editing.edit({
          cwd: this.cwd, text: original, config,
          onPrepared: (path) => { operation.recoveryFile = path; },
        });
      }), { signal: operation.controller.signal });
      if (Exit.isFailure(result)) {
        if (Cause.hasInterrupts(result.cause)) {
          if (operation.recoveryFile !== undefined) this.ui.notify(`Split edit interrupted. Saved prompt: ${operation.recoveryFile}`, "warning");
        } else {
          const error = result.cause.reasons.find(Cause.isFailReason)?.error;
          const message = error?.message ?? Cause.pretty(result.cause);
          const recovery = operation.recoveryFile === undefined ? "" : `\nSaved prompt: ${operation.recoveryFile}`;
          this.ui.notify(`split-editor: ${message}${recovery}`, "error");
        }
        return;
      }
      const saved = result.value;
      if (!this.active || this.getExpandedText() !== original) {
        this.ui.notify(`Prompt changed while editing; saved edit retained at ${saved.recoveryFile}`, "warning");
        return;
      }
      this.setText(saved.text);
      for (const warning of saved.warnings) this.ui.notify(warning, "warning");
      const removed = await this.runtime.runPromiseExit(saved.discardRecovery);
      if (Exit.isFailure(removed)) this.ui.notify(`Could not remove recovery file: ${saved.recoveryFile}`, "warning");
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.ui.notify(`split-editor defect: ${message}${operation.recoveryFile === undefined ? "" : `\nSaved prompt: ${operation.recoveryFile}`}`, "error");
    } finally {
      this.editing = undefined;
      if (this.active) this.tui.requestRender();
    }
  }
}

/** Install the live Herdr editor in TUI sessions only; shutdown cancels and awaits owned resources. */
export default function herdrSplitEditor(pi: ExtensionAPI): void {
  let runtime: Runtime | undefined;
  let editor: SplitEditor | undefined;
  let pendingStops: Promise<void> = Promise.resolve();
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    const currentRuntime = ManagedRuntime.make(layer(process.env.SHELL));
    runtime = currentRuntime;
    ctx.ui.setEditorComponent((tui, theme, bindings) => {
      // Pi can recreate components when appearance changes without replacing the session.
      pendingStops = Promise.all([pendingStops, editor?.stop()]).then(() => {});
      editor = new SplitEditor(tui, theme, bindings, ctx.ui, ctx.cwd, currentRuntime, () => ctx.isProjectTrusted() ? "trusted" : "untrusted", pendingStops);
      return editor;
    });
  });
  pi.on("session_shutdown", async (_event, ctx) => {
    await Promise.all([pendingStops, editor?.stop()]);
    pendingStops = Promise.resolve();
    editor = undefined;
    if (runtime !== undefined) {
      await runtime.dispose();
      runtime = undefined;
      ctx.ui.setEditorComponent(undefined);
    }
  });
}
