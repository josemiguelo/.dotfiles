#!/bin/sh
# The Pomodoro timer plugin (pomodoro-omarchy, installed by omarchy-plugins;
# where it sits on the bar is omarchy-bar-widgets'): its settings from
# omarchy-pomodoro/settings.json (set with `omarchy bar set` into its
# shell.json entry; keys the file doesn't list are left as they are), and a
# Pomodoro submenu under Trigger in the Omarchy menu (Keystroke serves it):
# omarchy-pomodoro/menu.jsonc, kept as a block in the menu's extensions
# (lib/menu-block.sh). They run the plugin's own
# bin/omarchy-pomodoro by its path, so nothing goes on the PATH.
# Modes: `check` / `install` (default).
set -eu

ID=pomodoro-omarchy
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC=$HERE/omarchy-pomodoro
. "$HERE/lib/plugin-update-hint.sh"
. "$HERE/lib/bar-widgets.sh"
. "$HERE/lib/menu-block.sh"
NOTE="Pomodoro under Trigger (loadouts/private_dot_config/.omarchy/.loadout/omarchy-pomodoro.sh rewrites this block)."

in_place() {
  widget_enabled "$ID" && widget_configured "$ID" "$SRC/settings.json" &&
    menu_block_in_place omarchy-pomodoro "$NOTE" "$SRC/menu.jsonc"
}

case "${1:-install}" in
check)
  in_place
  ;;
install)
  widget_enabled "$ID" || { echo "$ID isn't installed and enabled: add it to omarchy-plugins" >&2; exit 1; }
  widget_configured "$ID" "$SRC/settings.json" || widget_configure "$ID" "$SRC/settings.json"
  menu_block_write omarchy-pomodoro "$NOTE" "$SRC/menu.jsonc"
  in_place || { echo "the Pomodoro plugin isn't configured and in the menu after install" >&2; plugin_update_hint "$ID"; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
