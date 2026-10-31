import { Context, Effect, FileSystem, Layer, Schema } from "effect";
import { join } from "node:path";
import type { Config } from "./config.ts";

/** Terminal integration failure; raw provider errors stay in the adapter. */
export class PaneFailure extends Schema.TaggedError<PaneFailure>()("PaneFailure", {
  operation: Schema.String,
  message: Schema.String,
}) {}

/** The terminal-owned completion status, including forced pane closure. */
export type Completion =
  | { readonly _tag: "Exited"; readonly code: number }
  | { readonly _tag: "Closed" };

/** Application-owned terminal capability; implementations own their pane lifecycle. */
export class EditorPane extends Context.Service<EditorPane, {
  readonly edit: (input: {
    readonly cwd: string;
    readonly file: string;
    readonly status: string;
    readonly config: Config;
  }) => Effect.Effect<Completion, PaneFailure>;
}>()("herdr-split-editor/EditorPane") {}

/** Editing failed; a prepared prompt is retained at recoveryFile when available. */
export class EditFailure extends Schema.TaggedError<EditFailure>()("EditFailure", {
  message: Schema.String,
  recoveryFile: Schema.optionalKey(Schema.String),
}) {}

/** One edit request, including a recovery-path observer for the interactive adapter. */
export type EditRequest = {
  readonly cwd: string;
  readonly text: string;
  readonly config: Config;
  readonly onPrepared: (file: string) => void;
};

/** Saved prompt; discard its recovery copy only after successfully applying the text. */
export type EditResult = {
  readonly text: string;
  readonly recoveryFile: string;
  readonly warnings: ReadonlyArray<string>;
  readonly discardRecovery: Effect.Effect<void, EditFailure>;
};

/** Owns prompt-file lifetime, recovery, and read-back policy. */
export class Service extends Context.Service<Service, {
  readonly edit: (request: EditRequest) => Effect.Effect<EditResult, EditFailure>;
}>()("herdr-split-editor/SplitEditing") {}

/** Build editing policy from a filesystem and a lifecycle-owning terminal adapter. */
const make = Effect.gen(function* () {
  const fs = yield* FileSystem.FileSystem;
  const pane = yield* EditorPane;
  const edit = Effect.fn("SplitEditing.edit")(function* (request: EditRequest) {
    const directory = yield* fs.makeTempDirectory({ prefix: "pi-herdr-split-editor-" }).pipe(
      Effect.mapError(() => new EditFailure({ message: "Cannot create split-editor temporary directory" })),
    );
    const file = join(directory, "prompt.md");
    const run = Effect.gen(function* () {
      // mkdtemp is private (0700); keep the file private even with a permissive umask.
      yield* fs.writeFileString(file, request.text, { mode: 0o600 });
      request.onPrepared(file);
      const completion = yield* pane.edit({ cwd: request.cwd, file, status: join(directory, "status"), config: request.config });
      const text = (yield* fs.readFileString(file)).replace(/\r?\n$/, "");
      const warnings: string[] = [];
      if (completion._tag === "Closed") warnings.push("Editor pane closed without exit status; recovered the last saved prompt");
      else if (completion.code !== 0) warnings.push(`Editor exited with status ${completion.code}; recovered the last saved prompt`);
      // The UI acknowledges read-back separately, so replacement/cancellation cannot lose a saved edit.
      const discardRecovery = fs.remove(directory, { recursive: true, force: true }).pipe(
        Effect.mapError(() => new EditFailure({ message: "Could not remove split-editor temporary files", recoveryFile: file })),
      );
      return { text, recoveryFile: file, warnings, discardRecovery };
    });
    return yield* run.pipe(Effect.mapError((error) => new EditFailure({
      message: error._tag === "PaneFailure" ? error.message : "Cannot write/read split-editor prompt file",
      recoveryFile: file,
    })));
  });
  return Service.of({ edit });
});

/** Keep filesystem and terminal requirements visible to the composition root. */
export const layerWithoutDependencies = Layer.effect(Service, make);
