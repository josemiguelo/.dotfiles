#!/bin/sh
# Keystroke's Windows extension (every open window, grouped by workspace),
# the one Keystroke ships in its own extensions/ (since 1.5.1): turned on in
# ~/.config/omarchy/keystroke.json (providers.windows.enabled, the rest of the
# file kept), since every extension starts off. Hyper+Space
# (SUPER+CTRL+ALT+SHIFT+SPACE) opens the palette on its screen, from a block
# in ~/.config/hypr/bindings.lua. A copy under
# ~/.local/share/keystroke/extensions/ would replace the shipped one (that's
# where an author iterates on it), so the link an earlier version of this
# script made to a Keystroke checkout goes. The check reads the setting, and
# has hypr-option.lua evaluate the whole config: the key runs exactly that
# command. Install confirms the key in the running Hyprland when there is
# one, by description.
# Modes: `check` / `install` (default).
set -eu

BUNDLED=$HOME/.config/omarchy/plugins/evindor.keystroke/extensions/windows
OLD_LINK=$HOME/.local/share/keystroke/extensions/windows
SETTINGS=$HOME/.config/omarchy/keystroke.json
CONF=$HOME/.config/hypr/bindings.lua
HERE="$(cd "$(dirname "$0")" && pwd)"
PROBE=$HERE/../../../../lib/omarchy/hypr-option.lua
. "$HERE/../../../../lib/omarchy/hypr-live.sh"
. "$HERE/../../../../lib/omarchy/plugin-update-hint.sh"
BEGIN="-- >>> Managed by loadout (omarchy-keystroke-windows)"
END="-- <<< Managed by loadout (omarchy-keystroke-windows)"
KEY="SUPER + CTRL + ALT + SHIFT + SPACE"
COMMAND="omarchy-shell shell toggle omarchy.menu '{\"scope\":\"windows\",\"title\":\"Windows\"}'"
# modmask: SUPER 64 + CTRL 4 + ALT 8 + SHIFT 1.
MASK=77

block() {
  echo "$BEGIN"
  echo "-- Hyper+Space opens Keystroke on its Windows screen"
  echo "-- (configs/private_dot_config/.omarchy/.loadout/omarchy-keystroke-windows.sh rewrites this block)."
  echo "hl.unbind(\"$KEY\")"
  echo "o.bind(\"$KEY\", \"Windows\", [[$COMMAND]])"
  echo "$END"
}

current() {
  [ -f "$CONF" ] || return 0
  awk -v b="$BEGIN" -v e="$END" '$0 == b { keep = 1 } keep { print } $0 == e { keep = 0 }' "$CONF"
}

# Keystroke's own copy, not shadowed by a local one.
bundled() {
  [ -f "$BUNDLED/extension.json" ] && [ ! -e "$OLD_LINK" ] && [ ! -L "$OLD_LINK" ]
}

enabled() {
  [ -f "$SETTINGS" ] && jq -e '.providers.windows.enabled == true' "$SETTINGS" >/dev/null 2>&1
}

in_place() {
  bundled && enabled && [ "$(current)" = "$(block)" ] && [ "$(lua "$PROBE" "bind:$KEY")" = "$COMMAND" ]
}

case "${1:-install}" in
check)
  in_place
  ;;
install)
  [ -f "$BUNDLED/extension.json" ] || {
    echo "no Windows extension at $BUNDLED: is Keystroke (evindor.keystroke, from omarchy-plugins) 1.5.1 or later installed?" >&2
    plugin_update_hint evindor.keystroke
    exit 1
  }
  if [ -L "$OLD_LINK" ]; then
    rm "$OLD_LINK"
  elif [ -e "$OLD_LINK" ]; then
    echo "$OLD_LINK would replace Keystroke's own Windows extension; move it away first" >&2
    exit 1
  fi
  # Keystroke reloads the file when it changes and refuses one without
  # "version"; the new copy replaces the old one in a single rename.
  mkdir -p "$(dirname "$SETTINGS")"
  if [ -f "$SETTINGS" ]; then base=$(cat "$SETTINGS"); else base='{"version":1}'; fi
  tmp=$(mktemp "$SETTINGS.XXXXXX")
  printf '%s' "$base" | jq '.version //= 1 | .providers.windows.enabled = true' > "$tmp"
  mv "$tmp" "$SETTINGS"
  touch "$CONF"
  rest=$(awk -v b="$BEGIN" -v e="$END" '$0 == b { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$CONF")
  { printf '%s\n\n' "$rest"; block; } > "$CONF"
  in_place || { echo "Hyper+Space doesn't run only the Windows command after $CONF: something loaded later binds it" >&2; exit 1; }
  sig=$(live_instance)
  if [ -n "$sig" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl -q reload
    errors=$(HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl configerrors | grep -v '^[[:space:]]*$' || true)
    [ -z "$errors" ] || { echo "Hyprland reports config errors after the reload: $errors" >&2; exit 1; }
    got=$(HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl binds -j | jq -r --argjson m "$MASK" \
      '[.[] | select(.modmask == $m and .key == "SPACE") | .description] | join("|")')
    [ "$got" = "Windows" ] || { echo "the running Hyprland binds Hyper+Space to '$got', not 'Windows'" >&2; exit 1; }
  else
    echo "Hyprland isn't reachable from here; the key works at the next login."
  fi
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
