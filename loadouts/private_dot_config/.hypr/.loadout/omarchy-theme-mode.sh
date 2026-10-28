#!/bin/sh
# The machine's dark and light Omarchy themes, named by the opt-in
# ("omarchy-theme-mode tokyo-night catppuccin-latte"; spelled as
# `omarchy theme list` prints them works too), for
# ~/.local/bin/omarchy-theme-mode-toggle, which switches to the other one.
# The pair goes into ~/.config/omarchy/theme-mode.conf; Hyper+Enter
# (SUPER+CTRL+ALT+SHIFT+RETURN) runs the toggle, from a block in
# ~/.config/hypr/bindings.lua. Each theme must exist and be of its side, as
# omarchy-theme-color reads it. The check reads the file and has
# hypr-option.lua evaluate the whole config: the key runs exactly the toggle.
# Install confirms the key in the running Hyprland when there is one, by
# description.
# usage: omarchy-theme-mode.sh [check] <dark-theme> <light-theme>
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
[ $# -eq 2 ] || { echo "usage: $0 [check] <dark-theme> <light-theme>" >&2; exit 2; }

# A theme's folder name, as omarchy-theme-set makes it from what it's given.
name_of() {
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

DARK=$(name_of "$1")
LIGHT=$(name_of "$2")
SETTINGS=$HOME/.config/omarchy/theme-mode.conf
CONF=$HOME/.config/hypr/bindings.lua
HERE="$(cd "$(dirname "$0")" && pwd)"
PROBE=$HERE/../../.omarchy/.loadout/lib/hypr-option.lua
. "$HERE/../../.omarchy/.loadout/lib/hypr-live.sh"
BEGIN="-- >>> Managed by loadout (omarchy-theme-mode)"
END="-- <<< Managed by loadout (omarchy-theme-mode)"
KEY="SUPER + CTRL + ALT + SHIFT + RETURN"
COMMAND=omarchy-theme-mode-toggle
DESCRIPTION="Toggle light/dark theme"
# modmask: SUPER 64 + CTRL 4 + ALT 8 + SHIFT 1.
MASK=77

settings() {
  echo "# Managed by loadout (omarchy-theme-mode): the themes omarchy-theme-mode-toggle"
  echo "# switches between."
  echo "dark=$DARK"
  echo "light=$LIGHT"
}

block() {
  echo "$BEGIN"
  echo "-- Switches between the machine's dark and light theme"
  echo "-- (loadouts/private_dot_config/.hypr/.loadout/omarchy-theme-mode.sh rewrites this block)."
  echo "hl.unbind(\"$KEY\")"
  echo "o.bind(\"$KEY\", \"$DESCRIPTION\", \"$COMMAND\")"
  echo "$END"
}

current() {
  [ -f "$CONF" ] || return 0
  awk -v b="$BEGIN" -v e="$END" '$0 == b { keep = 1 } keep { print } $0 == e { keep = 0 }' "$CONF"
}

in_place() {
  [ -f "$SETTINGS" ] && [ "$(cat "$SETTINGS")" = "$(settings)" ] &&
    [ "$(current)" = "$(block)" ] && [ "$(lua "$PROBE" "bind:$KEY")" = "$COMMAND" ]
}

# Fails, saying why, unless theme $1 is installed and its mode is $2. A user
# theme of a stock name overlays the stock one (omarchy-theme-dir), so its
# colors.toml is read when it has one.
of_mode() {
  colors=
  for dir in "$HOME/.config/omarchy/themes/$1" "${OMARCHY_PATH:-/usr/share/omarchy}/themes/$1"; do
    if [ -f "$dir/colors.toml" ]; then colors=$dir/colors.toml; break; fi
  done
  [ -n "$colors" ] || { echo "no theme '$1' (see omarchy theme list)" >&2; return 1; }
  got=$(omarchy-theme-color --file "$colors" mode)
  [ "$got" = "$2" ] || { echo "theme '$1' is $got, not $2" >&2; return 1; }
}

case "$MODE" in
check)
  in_place
  ;;
install)
  of_mode "$DARK" dark
  of_mode "$LIGHT" light
  lua "$PROBE" "bind:$KEY" >/dev/null || exit 1
  mkdir -p "$(dirname "$SETTINGS")"
  settings > "$SETTINGS"
  touch "$CONF"
  rest=$(awk -v b="$BEGIN" -v e="$END" '$0 == b { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$CONF")
  { printf '%s\n\n' "$rest"; block; } > "$CONF"
  in_place || { echo "Hyper+Enter doesn't run only $COMMAND after $CONF: something loaded later binds it" >&2; exit 1; }
  sig=$(live_instance)
  if [ -n "$sig" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl -q reload
    errors=$(HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl configerrors | grep -v '^[[:space:]]*$' || true)
    [ -z "$errors" ] || { echo "Hyprland reports config errors after the reload: $errors" >&2; exit 1; }
    got=$(HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl binds -j | jq -r --argjson m "$MASK" \
      '[.[] | select(.modmask == $m and .key == "RETURN") | .description] | join("|")')
    [ "$got" = "$DESCRIPTION" ] || { echo "the running Hyprland binds Hyper+Enter to '$got', not '$DESCRIPTION'" >&2; exit 1; }
  else
    echo "Hyprland isn't reachable from here; the key works at the next login."
  fi
  ;;
esac
