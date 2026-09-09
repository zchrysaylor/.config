#!/usr/bin/env bash
# Read-only: total cards and distinct notes in a named deck, including subdecks.
set -euo pipefail
if [[ $# != 1 || ${1:-} == --help || -z ${1:-} ]]; then
  echo 'Usage: deck-count.sh "DECK NAME"   (includes subdecks)'
  [[ ${1:-} == --help ]] && exit 0
  exit 2
fi
source "$(dirname "${BASH_SOURCE[0]}")/_request.sh"

# Reject typos instead of reporting a nonexistent deck as empty.
printf '{}' | anki_request deckNames | jq -e --arg deck "$1" '
  if type != "array" then error("deckNames: expected an array")
  elif index($deck) == null then error("deck not found: " + $deck)
  else true end' > /dev/null
case "$1" in
  [Cc][Uu][Rr][Rr][Ee][Nn][Tt]|[Ff][Ii][Ll][Tt][Ee][Rr][Ee][Dd])
    echo 'Cannot count this name: Anki reserves it as a special deck search.' >&2
    exit 1 ;;
esac
# Escape Anki search metacharacters, not just JSON/shell quotes.
name=${1//\\/\\\\}
name=${name//\"/\\\"}
name=${name//\*/\\*}
name=${name//_/\\_}
params=$(jq -n --arg query "deck:\"$name\"" '{query:$query}')
counts=()
for action in findCards findNotes; do
  counts+=("$(printf '%s' "$params" | anki_request "$action" |
    jq 'if type == "array" and all(.[]; type == "number") then length
        else error("expected card/note IDs") end')")
done
jq -cn --arg deck "$1" --argjson cards "${counts[0]}" --argjson notes "${counts[1]}" \
  '{deck:$deck, includesSubdecks:true, cards:$cards, notes:$notes}'
