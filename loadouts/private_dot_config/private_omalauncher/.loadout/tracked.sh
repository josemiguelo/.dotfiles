#!/bin/sh
# The launcher's files on this phone, as they are, in the repo. They're
# edited on the phone (by hand, by agents, and by the launcher itself, which
# rewrites layout.toml as tiles move), so this goes phone -> repo, never back:
# a new file is added, a changed one re-added, and one deleted on the phone
# forgotten. The launcher's files: agent, style/style.toml, home/layout.toml
# and the top-level widgets/*.owl (not examples/, not the launcher's own
# dot files); the agents' instructions beside them are the repo's own.
# Modes: `check` / `install` (default) / `hook` (a Claude Code PostToolUse
# hook: the tool call's JSON on stdin; installs only when it wrote a launcher file).
set -eu

DIR="$HOME/.config/omalauncher"
SRC="${LOADOUT_CONFIGS:-$HOME/.local/share/chezmoi/loadouts}"
cz() { chezmoi --source "$SRC" --no-tty "$@"; }

is_launcher_file() {
  case "$1" in
  "$DIR"/widgets/*/*) return 1 ;;
  "$DIR"/widgets/*.owl | "$DIR"/style/style.toml | "$DIR"/home/layout.toml | "$DIR"/agent) return 0 ;;
  *) return 1 ;;
  esac
}

on_disk() {
  for f in "$DIR"/agent "$DIR"/style/style.toml "$DIR"/home/layout.toml "$DIR"/widgets/*.owl; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
}

managed() {
  cz managed --include files --path-style absolute | while IFS= read -r f; do
    if is_launcher_file "$f"; then printf '%s\n' "$f"; fi
  done
}

# untracked, changed and gone, one "<what> <path>" per line
pending() {
  m=$(managed)
  on_disk | while IFS= read -r f; do
    printf '%s\n' "$m" | grep -qxF -- "$f" || printf 'untracked %s\n' "$f"
  done
  printf '%s\n' "$m" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ ! -e "$f" ]; then
      printf 'gone %s\n' "$f"
    elif [ -n "$(cz status -- "$f")" ]; then
      printf 'changed %s\n' "$f"
    fi
  done
}

install() {
  pending | while read -r what f; do
    case "$what" in
    untracked) cz add -- "$f" && echo "added $f" ;;
    changed) cz re-add -- "$f" && echo "re-added $f" ;;
    gone) cz forget --force -- "$f" && echo "forgot $f" ;;
    esac
  done
}

case "${1:-install}" in
check)
  out=$(pending)
  [ -z "$out" ] && exit 0
  printf 'missing: %s\n' "$out"
  exit 1
  ;;
install) install ;;
hook)
  # file_path from the tool call, without jq: paths here hold no quotes.
  f=$(grep -o '"file_path" *: *"[^"]*"' | head -n 1 | sed 's/.*"\([^"]*\)"$/\1/')
  if [ -n "$f" ] && is_launcher_file "$f"; then install >/dev/null; fi
  ;;
*) echo "usage: $0 [check|install|hook]" >&2; exit 2 ;;
esac
