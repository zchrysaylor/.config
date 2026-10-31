import { Effect, FileSystem, Schema } from "effect";
import { join } from "node:path";

const NonEmptyCommand = Schema.String.check(
  Schema.isPattern(/\S/),
  // Unlike $, this end assertion cannot match before a trailing newline.
  Schema.isPattern(/^[^\0\r\n]+(?![\s\S])/),
);
const RawOptions = Schema.Struct({
  editor: Schema.optionalKey(NonEmptyCommand),
  size: Schema.optionalKey(Schema.String.check(Schema.isPattern(/^(?:[1-8][0-9]|90)%(?![\s\S])/))),
  direction: Schema.optionalKey(Schema.Literals(["h", "horizontal", "right", "v", "vertical", "down"])),
  showIndicator: Schema.optionalKey(Schema.Boolean),
});
const Settings = Schema.Struct({ splitEditor: Schema.optionalKey(RawOptions) });

/** Parsed options for one edit; size is the new pane's percentage. */
export type Config = {
  readonly editor: string;
  readonly size: string;
  readonly direction: "right" | "down";
  readonly showIndicator: boolean;
};

/** Invalid configuration, with its source but without potentially sensitive contents. */
export class ConfigFailure extends Schema.TaggedError<ConfigFailure>()("ConfigFailure", {
  source: Schema.String,
  message: Schema.String,
}) {}

/** Parse merged options and normalize tmux-compatible direction aliases. */
export const parse = (input: unknown, source = "splitEditor") =>
  Schema.decodeUnknownEffect(RawOptions)(input).pipe(
    Effect.map((raw): Config => ({
      editor: raw.editor?.trim() || "nvim",
      size: raw.size ?? "50%",
      direction: raw.direction === "v" || raw.direction === "vertical" || raw.direction === "down" ? "down" : "right",
      showIndicator: raw.showIndicator ?? true,
    })),
    Effect.mapError(() => new ConfigFailure({ source, message: `Invalid split-editor options in ${source}` })),
  );

/** Reload defaults, global/project files, settings, then environment for each invocation. */
export const load = Effect.fn("SplitEditor.loadConfig")(function* (
  agentDir: string,
  cwd: string,
  env: NodeJS.ProcessEnv,
  projectTrust: "trusted" | "untrusted" = "untrusted",
) {
  const fs = yield* FileSystem.FileSystem;
  const read = Effect.fn(function* (path: string, format: "settings" | "options") {
    const text = yield* fs.readFileString(path).pipe(
      Effect.catchIf((error) => error.reason._tag === "NotFound", () => Effect.succeed(undefined)),
      Effect.mapError(() => new ConfigFailure({ source: path, message: `Cannot read configuration: ${path}` })),
    );
    if (text === undefined) return {};
    if (format === "settings") {
      const parsed = yield* Schema.decodeUnknownEffect(Schema.fromJsonString(Settings))(text).pipe(
        Effect.mapError(() => new ConfigFailure({ source: path, message: `Invalid splitEditor settings: ${path}` })),
      );
      return parsed.splitEditor ?? {};
    }
    return yield* Schema.decodeUnknownEffect(Schema.fromJsonString(RawOptions))(text).pipe(
      Effect.mapError(() => new ConfigFailure({ source: path, message: `Invalid configuration: ${path}` })),
    );
  });
  const global = yield* read(join(agentDir, "extensions", "split-editor.json"), "options");
  const globalSettings = yield* read(join(agentDir, "settings.json"), "settings");
  // Editor commands are executable configuration. Never bypass Pi's project-trust decision.
  const project = projectTrust === "trusted" ? yield* read(join(cwd, ".pi", "split-editor.json"), "options") : {};
  const projectSettings = projectTrust === "trusted" ? yield* read(join(cwd, ".pi", "settings.json"), "settings") : {};
  const indicator = env.SPLIT_EDITOR_SHOW_INDICATOR?.trim().toLowerCase();
  if (indicator !== undefined && !["1", "true", "yes", "on", "0", "false", "no", "off"].includes(indicator)) {
    return yield* new ConfigFailure({ source: "SPLIT_EDITOR_SHOW_INDICATOR", message: "Invalid SPLIT_EDITOR_SHOW_INDICATOR boolean" });
  }
  const overrides = {
    ...(env.SPLIT_EDITOR_EDITOR === undefined ? {} : { editor: env.SPLIT_EDITOR_EDITOR }),
    ...(env.SPLIT_EDITOR_SIZE === undefined ? {} : { size: env.SPLIT_EDITOR_SIZE }),
    ...(env.SPLIT_EDITOR_DIRECTION === undefined ? {} : { direction: env.SPLIT_EDITOR_DIRECTION }),
    ...(indicator === undefined ? {} : { showIndicator: ["1", "true", "yes", "on"].includes(indicator) }),
  };
  return yield* parse({ ...global, ...globalSettings, ...project, ...projectSettings, ...overrides }, "merged configuration/environment");
});
