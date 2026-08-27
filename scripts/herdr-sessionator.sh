#!/bin/bash
set -euo pipefail

DIRS=(
  "$HOME/Code"
  "$HOME/Code/IdeaProjects/deliveryhero/"
  "$HOME/forge"
  "$HOME/Documents/geumgo"
)

if [[ $# -ge 1 ]]; then
  cwd=$1
else
  cwd=$(
    fd . "${DIRS[@]}" --type=dir --max-depth=1 --full-path |
      sed "s|^$HOME/||" |
      sk --margin 10%
  ) || exit 0

  [[ -n $cwd ]] || exit 0
  cwd="$HOME/$cwd"
fi

label=${2:-$(basename "$cwd" | tr . _)}
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

created=$(
  "$herdr_bin" workspace create \
    --cwd "$cwd" \
    --label "$label" \
    --focus
)

new_workspace_id=$(jq -r '.result.workspace.workspace_id' <<<"$created")
pi_tab_id=$(jq -r '.result.tab.tab_id' <<<"$created")
pi_pane_id=$(jq -r '.result.root_pane.pane_id' <<<"$created")
"$herdr_bin" tab rename "$pi_tab_id" pi >/dev/null
"$herdr_bin" pane run "$pi_pane_id" pi >/dev/null

"$herdr_bin" tab create \
  --workspace "$new_workspace_id" \
  --cwd "$cwd" \
  --label zsh \
  --focus \
  >/dev/null
