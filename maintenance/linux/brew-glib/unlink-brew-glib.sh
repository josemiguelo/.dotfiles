#!/bin/sh
# Linux: brew's glib (ffmpeg, scrcpy and SDL pull it in) unlinked. Linked, its
# gsettings, gio and gdbus sit in brew's bin, ahead of the system's on PATH,
# and brew's gsettings has no dconf backend: it writes to its own keyfile, so
# `omarchy theme set` run from a terminal never tells GTK or the desktop
# portal (kitty follows that) the theme went light or dark. Its dependents
# load it from brew's opt/, so they keep working unlinked; brew upgrade keeps
# an unlinked keg unlinked. Its build-only tools (gdbus-codegen,
# glib-mkenums…) leave PATH too: nothing here builds from source.
# Modes: `check` / `install` (default).
set -eu

brew() { sh "$LOADOUT_REPO/programs/brew/brew.sh" "$@"; }

# Without brew there's nothing to unlink.
. "$LOADOUT_REPO/configs/private_dot_local/lib/brew-prefix.sh"
command -v brew >/dev/null 2>&1 || [ -x "$BREW_PREFIX/bin/brew" ] || exit 0

linked() {
  [ -e "$BREW_PREFIX/bin/gsettings" ]
}

case "${1:-install}" in
check)
  if linked; then
    echo "brew's glib is linked: its gsettings shadows the system's"
    exit 1
  fi
  ;;
install)
  linked || exit 0
  brew unlink glib
  ! linked || { echo "$BREW_PREFIX/bin/gsettings is still there after brew unlink glib" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
