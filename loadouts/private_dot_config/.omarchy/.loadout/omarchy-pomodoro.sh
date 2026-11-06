#!/bin/sh
# The Pomodoro timer plugin (pomodoro-omarchy, installed by omarchy-plugins;
# where it sits on the bar is omarchy-bar-widgets'): its settings from
# omarchy-pomodoro/settings.json (set with `omarchy bar set` into its
# shell.json entry; keys the file doesn't list are left as they are), and a
# Pomodoro submenu under Trigger in the Omarchy menu (Keystroke serves it):
# omarchy-pomodoro/menu.jsonc, kept as a block right after the opening brace
# of ~/.config/omarchy/extensions/omarchy-menu.jsonc. Its entries end in
# commas; the menu's reader drops trailing ones. They run the plugin's own
# bin/omarchy-pomodoro by its path, so nothing goes on the PATH. The widget
# configured is the plugin's, or its clone (`omarchy plugin clone`,
# clonedFrom pomodoro-omarchy) once that has taken its place.
# Modes: `check` / `install` (default).
set -eu

ID=pomodoro-omarchy
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC=$HERE/omarchy-pomodoro
. "$HERE/lib/plugin-update-hint.sh"
JSON=$HOME/.config/omarchy/shell.json
MENU=$HOME/.config/omarchy/extensions/omarchy-menu.jsonc
BEGIN="  // >>> Managed by loadout (omarchy-pomodoro)"
END="  // <<< Managed by loadout (omarchy-pomodoro)"

enabled() {
  omarchy plugin list --json | jq -e --arg id "$1" 'any(.[]; .id == $id and .enabled)' >/dev/null
}

# The plugin's enabled clone, else the plugin.
effective() {
  omarchy plugin list --json | jq -r --arg id "$1" '[.[] | select(.enabled and .clonedFrom == $id) | .id][0] // $id'
}
WIDGET=$(effective "$ID")

configured() {
  jq -e -n --arg id "$WIDGET" --slurpfile want "$SRC/settings.json" --slurpfile shell "$JSON" '
    ([$shell[0].bar.layout[]?[]? | select(.id == $id)][0] // {}) as $entry
    | $want[0] | to_entries | all(.value == $entry[.key])' >/dev/null
}

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
  enabled "$WIDGET" && configured && [ "$(current)" = "$(block)" ]
}

case "${1:-install}" in
check)
  in_place
  ;;
install)
  enabled "$WIDGET" || { echo "$ID isn't installed and enabled: add it to omarchy-plugins" >&2; exit 1; }
  if ! configured; then
    for key in $(jq -r 'keys[]' "$SRC/settings.json"); do
      omarchy bar set "$WIDGET" "$key" "$(jq -c --arg k "$key" '.[$k]' "$SRC/settings.json")" --json >/dev/null
    done
  fi
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
