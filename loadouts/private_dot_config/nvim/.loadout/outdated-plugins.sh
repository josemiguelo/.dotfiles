#!/bin/sh
# The nvim-plugins updates source: with no arguments, the plugins Lazy calls
# outdated (`<plugin> <current> <candidate>` lines); `update <plugin>` moves
# one. Both go through plugins.sh, so Lazy stays the only writer of the pins.
set -eu
here=$(dirname "$0")

case "${1:-}" in
"") exec sh "$here/plugins.sh" outdated ;;
update) exec sh "$here/plugins.sh" update "${2:?usage: $0 update <plugin>}" ;;
*) echo "usage: $0 [update <plugin>]" >&2; exit 2 ;;
esac
