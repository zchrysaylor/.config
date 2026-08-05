#!/bin/sh
set -eu

cwd=$1
label=${2:-$(basename "$cwd")}
herdr_bin=${HERDR_BIN_PATH:-herdr}

workspace_id=$(
  "$herdr_bin" workspace list |
    jq -r --arg label "$label" \
      '.result.workspaces[] | select(.label == $label) | .workspace_id' |
    head -n 1
)

if [ -n "$workspace_id" ]; then
  exec "$herdr_bin" workspace focus "$workspace_id"
fi

exec "$herdr_bin" workspace create \
  --cwd "$cwd" \
  --label "$label" \
  --focus
