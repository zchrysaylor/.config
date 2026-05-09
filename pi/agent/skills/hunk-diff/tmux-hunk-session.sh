#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${TMUX:-}" ]]; then
  echo "Error: this script must be run from inside a tmux session." >&2
  exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
  echo "Error: tmux is not installed or not on PATH." >&2
  exit 1
fi

if ! command -v hunk >/dev/null 2>&1; then
  echo "Error: hunk is not installed or not on PATH." >&2
  exit 1
fi

# Create a new window in the current tmux session, starting in the current pane's
# working directory, and run hunk diff there.
tmux new-window -n "hunk-diff" -c "#{pane_current_path}" "hunk diff"
