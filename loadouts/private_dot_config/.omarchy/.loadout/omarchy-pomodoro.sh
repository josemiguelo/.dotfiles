#!/bin/sh
# The Pomodoro timer plugin (pomodoro-omarchy, installed by omarchy-plugins;
# where it sits on the bar is omarchy-bar-widgets'): its settings from
# omarchy-pomodoro/settings.json (set with `omarchy bar set` into its
# shell.json entry; keys the file doesn't list are left as they are), and a
# Pomodoro submenu under Trigger in the Omarchy menu (Keystroke serves it):
# omarchy-pomodoro/menu.jsonc, kept as a block right after the opening brace
# of ~/.config/omarchy/extensions/omarchy-menu.jsonc. Its entries end in
# commas; the menu's reader drops trailing ones. They run the plugin's own
# bin/omarchy-pomodoro by its path, so nothing goes on the PATH.
# Modes: `check` / `install` (default).
set -eu

ID=pomodoro-omarchy
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC=$HERE/omarchy-pomodoro
. "$HERE/lib/plugin-update-hint.sh"
. "$HERE/lib/bar-widgets.sh"
MENU=$HOME/.config/omarchy/extensions/omarchy-menu.jsonc
BEGIN="  // >>> Managed by loadout (omarchy-pomodoro)"
END="  // <<< Managed by loadout (omarchy-pomodoro)"

block() {
  echo "$BEGIN"
  echo "  // Pomodoro under Trigger (loadouts/private_dot_config/.omarchy/.loadout/omarchy-pomodoro.sh rewrites this block)."
  cat "$SRC/menu.jsonc"
  echo "$END"
}

current() {
  [ -f "$MENU" ] || return 0
  awk -v b="$BEGIN" -v e="$END" '$0 == b { keep = 1 } keep { print } $0 == e { keep = 0 }' "$MENU"
}

in_place() {
  widget_enabled "$ID" && widget_configured "$ID" "$SRC/settings.json" && [ "$(current)" = "$(block)" ]
}

case "${1:-install}" in
check)
  in_place
  ;;
install)
  widget_enabled "$ID" || { echo "$ID isn't installed and enabled: add it to omarchy-plugins" >&2; exit 1; }
  widget_configured "$ID" "$SRC/settings.json" || widget_configure "$ID" "$SRC/settings.json"
  mkdir -p "$(dirname "$MENU")"
  [ -f "$MENU" ] || printf '{\n}\n' > "$MENU"
  grep -q '^[[:space:]]*{' "$MENU" || { echo "$MENU has no opening brace to put the menu entries after" >&2; exit 1; }
  # The file without the old block, the block right after the first line
  # that opens the object.
  rest=$(awk -v b="$BEGIN" -v e="$END" '$0 == b { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$MENU")
  {
    printf '%s\n' "$rest" | awk '/^[[:space:]]*\{/ { print; exit } { print }'
    block
    printf '%s\n' "$rest" | awk 'found { print } !found && /^[[:space:]]*\{/ { found = 1 }'
  } > "$MENU.tmp"
  mv "$MENU.tmp" "$MENU"
  in_place || { echo "the Pomodoro plugin isn't configured and in the menu after install" >&2; plugin_update_hint "$ID"; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
