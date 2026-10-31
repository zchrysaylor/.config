# Herdr Split Editor

A Pi extension for editing prompts in a live Herdr pane. Requires Pi, Herdr on `PATH`, and Node.js 22.19 or newer.

Heavily inspired by the awesome [split-editor](https://github.com/kaiole/split-editor) extension for Pi/tmux; essentially just a rewrite in Effect v4 for Herdr.

## Installation

Clone or download this extension, then run from its directory:

```bash
npm ci --omit=dev --ignore-scripts --legacy-peer-deps
pi install .
```

Alternatively, place the directory under `<agent-dir>/extensions/herdr-split-editor/` after installing dependencies. Pi discovers `src/index.ts` through `package.json`; no root entrypoint or explicit settings entry is needed.

## Usage

Run `/reload`, type a prompt, then press Ctrl+G. Herdr opens a focused sibling pane running `nvim`. Save and quit to put the saved text back into Pi's prompt. The editor starts directly as the pane's initial process, without initializing zsh or typing a launch command. Pi stays visible and resize-aware; local prompt input is locked until editing finishes.

The configured `app.editor.external` keybinding is honored. Press Escape or Ctrl+C in Pi to cancel the split edit without clearing the prompt; these follow the `app.interrupt` and `app.clear` bindings. Outside Herdr, the external-editor action falls through to Pi's normal editor. RPC and print sessions do not install the custom editor.

To load it for one Pi invocation from any project:

```bash
pi -e /path/to/herdr-split-editor
```

## Configuration

Options reload on every edit:

| Option | Environment | Default |
| --- | --- | --- |
| `editor` | `SPLIT_EDITOR_EDITOR` | `nvim` |
| `size` | `SPLIT_EDITOR_SIZE` | `50%` |
| `direction` | `SPLIT_EDITOR_DIRECTION` | `h` |
| `showIndicator` | `SPLIT_EDITOR_SHOW_INDICATOR` | `true` |

Size is the new editor pane's share, from `10%` through `90%`. Cell counts are not supported. Direction accepts `h`, `horizontal`, or `right` for side-by-side; `v`, `vertical`, or `down` for stacked panes. Boolean environment values accept `1/true/yes/on` and `0/false/no/off`.

Precedence, lowest first:

1. Defaults.
2. `<agent-dir>/extensions/split-editor.json`, with options directly in the object.
3. `<agent-dir>/settings.json`, under `splitEditor`.
4. `<cwd>/.pi/split-editor.json`, with options directly in the object.
5. `<cwd>/.pi/settings.json`, under `splitEditor`.
6. Environment variables.

Project files are read only when Pi reports the project trusted. Standalone configuration alone does not trigger Pi's trust prompt; use `/trust` if needed. Editor commands are shell code, so only use configuration you trust. Invalid options or malformed JSON are reported without overwriting the prompt.

Example Pi settings fragment:

```json
{
  "splitEditor": {
    "editor": "nvim -u NONE",
    "size": "40%",
    "direction": "right",
    "showIndicator": true
  }
}
```

## Recovery and limitations

- Nonzero editor exits and manual pane closure still read the last saved file, with a warning.
- Failures, interrupted sessions, and concurrent programmatic prompt changes retain `prompt.md` in a private temporary directory. The notification gives its path. Read it before removing the directory.
- Closing a pane cannot recover changes that the editor never saved.
- Only the pane created for this edit is closed. Do not move it to another workspace while editing; moved panes receive different IDs. If a split request fails before returning its ID, inspect the Herdr layout for an unclaimed pane.
- Requires Herdr's login-shell launch mode: `[terminal] shell_mode = "auto"` on macOS (the default), or `"login"`. There is no interactive-shell compatibility path.
- Startup is bounded to 10 seconds; active editing has no deadline. The wrapper restores the caller's `$SHELL` before starting the editor.
- This implementation uses POSIX `/bin/sh`. It replaces Pi's main editor component, so do not enable a competing editor-replacement extension.

