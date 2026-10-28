#!/bin/sh
# How long the session sits idle before the shell locks it (and turns the
# display off, which also ends the screensaver), from the machine's opt-in
# ("omarchy-idle 1000"). It's Omarchy's own setting, idle.lock in
# ~/.config/omarchy/shell.json, in seconds; idle.screensaver (when the
# screensaver starts) is left as it is. Only the key is set, the rest of the
# file is kept; a missing or empty file starts from Omarchy's defaults, as
# Omarchy's own editing does (omarchy-shell-config), since the shell reads a
# user file in their place, not over them. The shell is told to reload.
# usage: omarchy-idle.sh [check] <lock-seconds>
set -eu

USAGE="usage: $0 [check] <lock-seconds>"
MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
LOCK=${1:?$USAGE}
case "$LOCK" in '' | *[!0-9]*) echo "lock-seconds must be a whole number" >&2; exit 2 ;; esac

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/shell-ready.sh"
JSON=$HOME/.config/omarchy/shell.json
DEFAULTS=${OMARCHY_PATH:-/usr/share/omarchy}/config/omarchy/shell.json

set_already() {
  [ -s "$JSON" ] && jq -e --argjson lock "$LOCK" '.idle.lock == $lock' "$JSON" >/dev/null
}

case "$MODE" in
check)
  set_already
  ;;
install)
  if ! set_already; then
    from=$JSON
    [ -s "$JSON" ] || from=$DEFAULTS
    mkdir -p "$(dirname "$JSON")"
    tmp=$(mktemp "$JSON.XXXXXX")
    jq --argjson lock "$LOCK" '.version = 1 | .idle = ((.idle // {}) + { lock: $lock })' "$from" > "$tmp"
    mv "$tmp" "$JSON"
    shell_ready && omarchy-shell shell reloadConfig >/dev/null 2>&1 || true
  fi
  set_already || { echo "$JSON's idle.lock isn't $LOCK after install" >&2; exit 1; }
  ;;
esac
