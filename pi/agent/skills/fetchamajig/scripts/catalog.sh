#!/usr/bin/env bash
set -euo pipefail

# Requires jq. Metadata stays outside the disposable repository checkouts.
root="$HOME/.fetchamajig"
backshop="$root/backshop"
catalog="$root/catalog.json"
mkdir -p "$backshop"
if [[ ! -f "$catalog" ]]; then
  printf '%s\n' '{"version":1,"repos":{}}' > "$catalog"
fi

case "${1:-list}" in
  list)
    shopt -s nullglob
    for path in "$backshop"/*/*; do
      [[ -e "$path/.git" ]] || continue
      repo="${path#"$backshop/"}"
      jq --arg repo "$repo" --arg path "$path" \
        '{repo: $repo, path: $path, description: (.repos[$repo].description // null)}' \
        "$catalog"
    done | jq -s '.'
    ;;
  describe)
    if [[ $# -ne 3 ]]; then
      echo 'Usage: catalog.sh describe <owner/repo> "One-sentence description"' >&2
      exit 1
    fi
    repo="$2"
    if [[ ! "$repo" =~ ^[[:alnum:]_.-]+/[[:alnum:]_.-]+$ || "$repo" == *..* || ! -e "$backshop/$repo/.git" ]]; then
      echo "Not a cached owner/repo checkout: $repo" >&2
      exit 1
    fi
    tmp=$(mktemp "$root/catalog.json.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    jq --arg repo "$repo" --arg description "$3" \
      '.repos[$repo] = {description: $description}' "$catalog" > "$tmp"
    mv "$tmp" "$catalog"
    ;;
  *)
    echo 'Usage: catalog.sh list | describe <owner/repo> "One-sentence description"' >&2
    exit 1
    ;;
esac
