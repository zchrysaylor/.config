#!/usr/bin/env bash
# Read-only: find matching notes and emit their unmodified notesInfo JSON array.
set -euo pipefail
if [[ $# != 1 || ${1:-} == --help || -z ${1:-} ]]; then
  echo "Usage: fetch-notes.sh 'ANKI QUERY' > notes.json"
  [[ ${1:-} == --help ]] && exit 0
  exit 2
fi
source "$(dirname "${BASH_SOURCE[0]}")/_request.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
jq -n --arg query "$1" '{query:$query}' | anki_request findNotes |
  jq 'if type == "array" and all(.[]; type == "number") then .
      else error("findNotes: expected note IDs") end' > "$work/ids.json"
count=$(jq length "$work/ids.json")
: > "$work/notes.jsonl"
for ((offset=0; offset<count; offset+=500)); do
  jq --argjson offset "$offset" '{notes:.[$offset:$offset+500]}' \
    "$work/ids.json" > "$work/batch.json"
  anki_request notesInfo < "$work/batch.json" |
    jq --slurpfile batch "$work/batch.json" '
      if type != "array" then error("notesInfo: expected an array")
      elif (map(.noteId) | sort) != ($batch[0].notes | sort) then
        error("notesInfo: missing or unexpected notes; run a fresh search")
      else . end' >> "$work/notes.jsonl"
done
# Emit nothing until every batch has succeeded; an empty search returns [].
jq -cs 'add // []' "$work/notes.jsonl"
