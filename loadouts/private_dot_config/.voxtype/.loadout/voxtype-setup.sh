#!/bin/sh
# Voxtype's first-time setup on macOS: the speech model and hotkey
# (`voxtype configure`, interactive) and /Applications/Voxtype.app, which the
# privacy permissions belong to. Pending until the app exists, so the steps
# stay on the list instead of scrolling past after the install. The
# permissions can't be granted from a script: they're printed at the end.
# Modes: `check` (Voxtype.app present?) / `install` (default).
set -eu

APP=/Applications/Voxtype.app

case "${1:-install}" in
check)
  test -d "$APP"
  exit $?
  ;;
install) ;;
*)
  echo "usage: $0 [check|install]" >&2
  exit 2
  ;;
esac

# Run before the dotfiles put brew on PATH, so reach it by its prefix.
. "$LOADOUT_REPO/loadouts/private_dot_local/lib/brew-prefix.sh"
voxtype="$BREW_PREFIX/bin/voxtype"

"$voxtype" configure
sudo "$voxtype" setup app-bundle

# What's left is in System Settings: from the help's permissions step on.
awk '/^  3\. Permissions/ { p = 1 } p' "$(dirname "$0")/voxtype-help.txt"
