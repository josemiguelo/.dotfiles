#!/bin/sh
# The "Split view keys" extension (~/.config/surfingkeys/split-view) on
# Brave's --load-extension line in ~/.config/brave-flags.conf. Omarchy writes
# that file and loads its own extensions on that line, and Chromium reads only
# the last --load-extension, so this joins its list. If Omarchy rewrites the
# file, `check` fails and `install` adds it again. Brave reads the file when it
# starts. Modes: `check` / `install` (default).
set -eu

flags="${XDG_CONFIG_HOME:-$HOME/.config}/brave-flags.conf"
ext="${XDG_CONFIG_HOME:-$HOME/.config}/surfingkeys/split-view"

# The number of the last --load-extension line, empty without one.
last_line() {
  grep -n '^--load-extension=' "$flags" | tail -n 1 | cut -d: -f1
}

ready() {
  [ -f "$flags" ] || return 1
  line=$(last_line)
  [ -n "$line" ] || return 1
  sed -n "${line}p" "$flags" | cut -d= -f2- | tr , '\n' | grep -qxF "$ext"
}

case "${1:-install}" in
check)
  ready
  ;;
install)
  ready && exit 0
  [ -f "$flags" ] || { echo "$flags is missing: set up Brave first" >&2; exit 1; }
  line=$(last_line)
  if [ -n "$line" ]; then
    awk -v line="$line" -v ext="$ext" 'NR == line { $0 = $0 "," ext } 1' "$flags" >"$flags.tmp"
    mv "$flags.tmp" "$flags"
  else
    printf -- '--load-extension=%s\n' "$ext" >>"$flags"
  fi
  echo "Restart Brave to load the Split view keys extension" >&2
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
