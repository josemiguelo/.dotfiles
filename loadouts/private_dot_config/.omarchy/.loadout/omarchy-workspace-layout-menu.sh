#!/bin/sh
# The Omarchy menu's layout entries (Appearance; Keystroke serves the menu):
# "This Workspace's Layout", one entry per layout that changes the focused
# workspace only (omarchy-workspace-layout-set, in ~/.local/bin), beside
# Omarchy's own entry, relabelled "Default Workspace Layout" since it sets the
# layout of new and empty workspaces, never one with windows. The entries are
# omarchy-workspace-layout-menu/menu.jsonc, kept as a block in the menu's
# extensions (lib/menu-block.sh). Done = the block as written and the command
# on the PATH.
# Modes: `check` / `install` (default).
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC=$HERE/omarchy-workspace-layout-menu
. "$HERE/lib/menu-block.sh"
NAME=omarchy-workspace-layout-menu
NOTE="Layout entries under Appearance (loadouts/private_dot_config/.omarchy/.loadout/omarchy-workspace-layout-menu.sh rewrites this block)."

in_place() {
  command -v omarchy-workspace-layout-set >/dev/null && menu_block_in_place "$NAME" "$NOTE" "$SRC/menu.jsonc"
}

case "${1:-install}" in
check)
  in_place
  ;;
install)
  command -v omarchy-workspace-layout-set >/dev/null ||
    { echo "omarchy-workspace-layout-set isn't on the PATH: chezmoi apply puts it in ~/.local/bin" >&2; exit 1; }
  menu_block_write "$NAME" "$NOTE" "$SRC/menu.jsonc"
  in_place || { echo "the layout entries aren't in $MENU after install" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
