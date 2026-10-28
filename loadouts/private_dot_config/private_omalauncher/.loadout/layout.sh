#!/bin/sh
# Home as layout.toml says. When the dotfiles land all at once (a new
# install's chezmoi apply), the launcher can read layout.toml before it sees
# the widgets it names, leave them out ("x.owl isn't in widgets/; left out"
# in home/errors.txt) and not look again once they're there. It re-reads the
# file only when its content changes, so this appends a comment, waits for
# the launcher to take it, and takes it out again: the file ends as it was.
# Modes: `check` / `install` (default).
set -eu

DIR="$HOME/.config/omalauncher"
LAYOUT="$DIR/home/layout.toml"
ERRORS="$DIR/home/errors.txt"
MARK="# omalauncher-layout: read again"

# The widgets errors.txt says are missing that are there now, one per line.
stale() {
  [ -f "$ERRORS" ] || return 0
  grep -o "[^ ]*\.owl isn't in widgets/" "$ERRORS" | sed 's/ .*//' | sort -u | while IFS= read -r w; do
    [ -f "$DIR/widgets/$w" ] && printf '%s\n' "$w"
  done
}

errors_stamp() { stat -c %y "$ERRORS" 2>/dev/null || echo gone; }

# Until errors.txt changes (rewritten or removed), up to 10s.
await_read() {
  i=0
  while [ "$(errors_stamp)" = "$1" ] && [ "$i" -lt 20 ]; do
    sleep 0.5
    i=$((i + 1))
  done
}

reread() {
  before=$(errors_stamp)
  printf '%s\n' "$MARK" >>"$LAYOUT"
  await_read "$before"
  # Only the mark goes: the launcher may have rewritten the file meanwhile.
  tmp="$LAYOUT.omalauncher-layout"
  grep -vxF -- "$MARK" "$LAYOUT" >"$tmp" || true
  cat "$tmp" >"$LAYOUT"
  rm -f "$tmp"
  sleep 2
}

case "${1:-install}" in
check)
  out=$(stale)
  [ -z "$out" ] && exit 0
  printf 'left out though in widgets/: %s\n' $out
  exit 1
  ;;
install)
  [ -f "$LAYOUT" ] || exit 0
  [ -z "$(stale)" ] || reread
  out=$(stale)
  [ -z "$out" ] || { printf 'still left out: %s (see %s)\n' "$(echo $out)" "$ERRORS" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
