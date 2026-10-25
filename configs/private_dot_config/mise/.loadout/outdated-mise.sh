#!/bin/sh
# mise's own outdated check where mise.run installed it (the mise-run variant,
# omalauncher's): is ~/.local/bin/mise behind mise's latest GitHub release?
# No package manager knows about that binary, and `mise self-update` updates
# it in place.
#
#   outdated-mise.sh          print the latest version when behind, else nothing
#   outdated-mise.sh update   update the binary to the latest release
#
# Silent where mise isn't that binary (Omarchy's mise-bin and brew's mise are
# their installers' to report) and when the network is down.
set -eu

BIN="$HOME/.local/bin/mise"

current() {
  [ -x "$BIN" ] || return 0
  "$BIN" version 2>/dev/null | awk 'NR == 1 { print $1 }'
}

latest() {
  curl -fsSL https://api.github.com/repos/jdx/mise/releases/latest 2>/dev/null |
    sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -n 1
}

case "${1:-}" in
update) "$BIN" self-update --yes ;;
"")
  now=$(current)
  [ -n "$now" ] || exit 0
  new=$(latest || true)
  if [ -n "$new" ] && [ "$new" != "$now" ]; then echo "$new"; fi
  ;;
*) echo "usage: $0 [update]" >&2; exit 2 ;;
esac
