#!/bin/sh
# The mason-kotlin-lsp updates source: with no arguments, `kotlin-lsp
# <installed> <latest>` when Mason has a newer build; `update <item>` has
# Mason install it. Both go through mason-kotlin-lsp.sh.
set -eu
here=$(dirname "$0")

case "${1:-}" in
"") exec sh "$here/mason-kotlin-lsp.sh" outdated ;;
update) exec sh "$here/mason-kotlin-lsp.sh" install ;;
*) echo "usage: $0 [update <item>]" >&2; exit 2 ;;
esac
