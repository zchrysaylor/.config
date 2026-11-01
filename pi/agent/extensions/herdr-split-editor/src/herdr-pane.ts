import { Effect, FileSystem, Layer, Option, Schema, Stream } from "effect";
import { ChildProcess, ChildProcessSpawner } from "effect/process";
import { EditorPane, PaneFailure } from "./split-editing.ts";

const Envelope = Schema.Struct({
  result: Schema.optionalKey(Schema.Unknown),
  error: Schema.optionalKey(Schema.Struct({ code: Schema.String })),
});
const PaneResponse = Schema.Struct({ pane: Schema.Struct({
  pane_id: Schema.String.check(Schema.isMinLength(1)).pipe(Schema.brand("EditorPaneId")),
}) });
const ExitStatus = Schema.NumberFromString.check(Schema.isInt(), Schema.isBetween({ minimum: 0, maximum: 255 }));

function quote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

/** Build the direct-launch adapter, restoring the caller's SHELL before invoking the editor. */
const make = (originalShell: string | undefined) => Effect.gen(function* () {
  const fs = yield* FileSystem.FileSystem;
  const spawner = yield* ChildProcessSpawner.ChildProcessSpawner;
  const call = Effect.fn("Herdr.call")(function* (args: ReadonlyArray<string>) {
    const operation = args.slice(0, 2).join(" ");
    const output = yield* Effect.scoped(Effect.gen(function* () {
      const child = yield* spawner.spawn(ChildProcess.make("herdr", args, {
        stdin: "ignore", stdout: "pipe", stderr: "pipe", forceKillAfter: "500 millis",
      }));
      const [code, stdout, stderr] = yield* Effect.all([
        child.exitCode,
        Stream.mkString(Stream.decodeText(child.stdout)),
        Stream.mkString(Stream.decodeText(child.stderr)),
      ], { concurrency: "unbounded" });
      return { code, stdout, stderr };
    })).pipe(
      Effect.timeout("5 seconds"),
      Effect.mapError(() => new PaneFailure({ operation, message: `Herdr ${operation} failed or timed out; check 'herdr status'` })),
    );
    const body = output.code === 0 ? output.stdout : output.stderr;
    const envelope = yield* Schema.decodeUnknownEffect(Schema.fromJsonString(Envelope))(body).pipe(
      Effect.mapError(() => new PaneFailure({ operation, message: `Herdr ${operation} returned an invalid response (exit ${output.code})` })),
    );
    if (envelope.error !== undefined) {
      return { _tag: "Rejected", code: envelope.error.code } as const;
    }
    if (output.code !== 0 || envelope.result === undefined) {
      return yield* new PaneFailure({ operation, message: `Herdr ${operation} failed (exit ${output.code})` });
    }
    return { _tag: "Succeeded", value: envelope.result } as const;
  });
  const requireSuccess = Effect.fn(function* (args: ReadonlyArray<string>) {
    const response = yield* call(args);
    if (response._tag === "Rejected") {
      return yield* new PaneFailure({ operation: args.slice(0, 2).join(" "), message: `Herdr rejected ${args.slice(0, 2).join(" ")}: ${response.code}` });
    }
    return response.value;
  });
  const edit: EditorPane["Service"]["edit"] = Effect.fn("Herdr.edit")(function* (input) {
    const started = `${input.status}.started`;
    const script = `${input.status}.sh`;
    const temporaryStatus = `${input.status}.tmp`;
    const finish = `code=$?; trap - EXIT; printf '%s\\n' "$code" > ${quote(temporaryStatus)} && mv ${quote(temporaryStatus)} ${quote(input.status)}`;
    yield* fs.writeFileString(script, [
      "#!/bin/sh",
      // SHELL pointed to this wrapper only for Herdr's initial process selection.
      originalShell === undefined ? "unset SHELL" : `export SHELL=${quote(originalShell)}`,
      `trap ${quote(finish)} EXIT`,
      "trap 'exit 129' HUP",
      "trap 'exit 130' INT",
      "trap 'exit 143' TERM",
      `: > ${quote(started)}`,
      `${input.config.editor} ${quote(input.file)}`,
      "",
    ].join("\n"), { mode: 0o700 }).pipe(
      Effect.mapError(() => new PaneFailure({ operation: "prepare", message: "Cannot write editor wrapper" })),
    );
    const readStatus = Effect.gen(function* () {
      const status = yield* fs.readFileString(input.status).pipe(
        Effect.catchIf((error) => error.reason._tag === "NotFound", () => Effect.succeed(undefined)),
        Effect.mapError(() => new PaneFailure({ operation: "status", message: "Cannot read editor status" })),
      );
      if (status === undefined) return undefined;
      const code = yield* Schema.decodeUnknownEffect(ExitStatus)(status.trim()).pipe(
        Effect.mapError(() => new PaneFailure({ operation: "status", message: "Invalid editor exit status" })),
      );
      return { _tag: "Exited", code } as const;
    });
    let closeFailure: PaneFailure | undefined;
    const result = yield* Effect.scoped(Effect.gen(function* () {
      const pane = yield* Effect.acquireRelease(
        Effect.gen(function* () {
          const value = yield* requireSuccess([
            "pane", "split", "--current", "--direction", input.config.direction,
            // Herdr's ratio belongs to the original (first) pane, not the new editor pane.
            "--ratio", String(1 - Number.parseInt(input.config.size, 10) / 100),
            "--cwd", input.cwd, "--env", `SHELL=${script}`, "--focus",
          ]);
          return yield* Schema.decodeUnknownEffect(PaneResponse)(value).pipe(
            Effect.mapError(() => new PaneFailure({ operation: "split", message: "Herdr split response has no pane ID; inspect the layout for an unclaimed pane" })),
          );
        }),
        (created) => Effect.gen(function* () {
          const closed = yield* call(["pane", "close", created.pane.pane_id]).pipe(Effect.result);
          if (closed._tag === "Failure") closeFailure = closed.failure;
          else if (closed.success._tag === "Rejected" && closed.success.code !== "pane_not_found") {
            closeFailure = new PaneFailure({ operation: "close", message: `Could not close editor pane ${created.pane.pane_id}: ${closed.success.code}` });
          }
        }),
      );
      const id = pane.pane.pane_id;
      const exists = Effect.gen(function* () {
        const response = yield* call(["pane", "get", id]);
        if (response._tag === "Succeeded") return true;
        if (response.code === "pane_not_found") return false;
        return yield* new PaneFailure({ operation: "get", message: `Cannot inspect editor pane: ${response.code}` });
      });
      // A non-login Herdr launch ignores the SHELL override. Fail rather than typing a fallback command.
      const startup = yield* Effect.gen(function* () {
        while (true) {
          if (yield* fs.exists(started)) return true;
          if (!(yield* exists)) return false;
          // Avoid repeatedly spawning Herdr while its login shell is still starting.
          yield* Effect.sleep("500 millis");
        }
      }).pipe(
        Effect.timeoutOption("10 seconds"),
        Effect.mapError(() => new PaneFailure({ operation: "startup", message: "Cannot inspect editor startup" })),
      );
      if (Option.isNone(startup)) return yield* new PaneFailure({ operation: "startup", message: "Direct editor launch did not start within 10 seconds; Herdr terminal.shell_mode must be auto (macOS) or login" });
      if (!startup.value) return yield* new PaneFailure({ operation: "startup", message: "Editor pane closed before the editor started" });
      while (true) {
        const status = yield* readStatus;
        if (status !== undefined) return status;
        if (!(yield* exists)) {
          // Re-read after detecting closure: the wrapper may have written status during the CLI call.
          return (yield* readStatus) ?? { _tag: "Closed" } as const;
        }
        // Pane closure is user-driven; one status process per second is responsive without
        // continuously spawning Herdr for the duration of a long edit.
        yield* Effect.sleep("1 second");
      }
    }));
    if (closeFailure !== undefined) return yield* closeFailure;
    return result;
  });
  return EditorPane.of({ edit });
});

/** Leave process/filesystem providers and the original shell snapshot to the composition root. */
export const layerWithoutDependencies = (originalShell: string | undefined) => Layer.effect(EditorPane, make(originalShell));
