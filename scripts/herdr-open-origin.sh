#!/usr/bin/env bash
set -euo pipefail

cd -- "${HERDR_ACTIVE_PANE_CWD:-$PWD}"

url=$(git remote get-url origin 2>/dev/null) || {
    echo "No origin remote found" >&2
    exit 1
}

# Convert common SSH remote formats to browser URLs. SSH config aliases
# identify credentials, not necessarily the public web hostname.
host=""
path=""
case "$url" in
    git@*:*)
        url="${url#git@}"
        host="${url%%:*}"
        path="${url#*:}"
        ;;
    ssh://git@*)
        url="${url#ssh://git@}"
        host="${url%%/*}"
        path="${url#*/}"
        ;;
esac

case "$host" in
    github-personal) host=github.com ;;
esac

if [[ -n "$host" ]]; then
    url="https://${host}/${path}"
fi

open "${url%.git}"
