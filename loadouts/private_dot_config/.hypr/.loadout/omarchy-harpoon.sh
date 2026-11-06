#!/bin/sh
# App and scratchpad hotkeys on Hyper, like Raycast's, with
# github.com/josemiguelo/omarchy-harpoon: an Omarchy shell plugin
# (josemiguelo.harpoon, the card naming the workspace you land on) that
# omarchy-plugins installs, and its engine, hypr/harpoon.lua, linked as
# ~/.config/hypr/harpoon.lua so Hyprland's Lua loads it as hypr.harpoon and
# `omarchy plugin update` updates it. omarchy-harpoon/bindings.lua is the apps
# and keys, kept as a block in ~/.config/hypr/bindings.lua, Omarchy's personal-bindings
# file, with Omarchy's scratchpad moved from SUPER+S to Hyper+Escape. Hyper
# is SUPER+CTRL+ALT+SHIFT, which the keyboard sends from one key (Keychron
# Launcher); Omarchy binds nothing on it. The check wants the link, the block
# as the repo has it and the plugin enabled, and has
# hypr-option.lua evaluate the whole config: each key runs exactly one
# binding, Hyper+Escape the scratchpad and SUPER+S nothing. Install rewrites the block between its markers and confirms the
# keys in the running Hyprland when there is one — by description, since with
# a Lua config hyprctl binds shows a function reference, never the action.
# Modes: `check` / `install` (default).
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC=$HERE/omarchy-harpoon
ENGINE=$HOME/.config/hypr/harpoon.lua
CONF=$HOME/.config/hypr/bindings.lua
PROBE=$HERE/../../.omarchy/.loadout/lib/hypr-option.lua
. "$HERE/../../.omarchy/.loadout/lib/hypr-live.sh"
BEGIN="-- >>> Managed by loadout (omarchy-harpoon)"
END="-- <<< Managed by loadout (omarchy-harpoon)"
HYPER="SUPER + CTRL + ALT + SHIFT"
# modmask: SUPER 64 + CTRL 4 + ALT 8 + SHIFT 1.
MASK=77
PLUGIN_ID=josemiguelo.harpoon
TARGET=$HOME/.config/omarchy/plugins/$PLUGIN_ID/hypr/harpoon.lua

linked() {
  [ -L "$ENGINE" ] && [ "$(readlink "$ENGINE")" = "$TARGET" ] && [ -f "$TARGET" ]
}

plugin_enabled() {
  omarchy plugin list --json 2>/dev/null |
    jq -e --arg id "$PLUGIN_ID" 'any(.[]; .id == $id and .enabled)' >/dev/null
}

block() {
  echo "$BEGIN"
  cat "$SRC/bindings.lua"
  echo "$END"
}

current() {
  [ -f "$CONF" ] || return 0
  awk -v b="$BEGIN" -v e="$END" '$0 == b { keep = 1 } keep { print } $0 == e { keep = 0 }' "$CONF"
}

# The letters bindings.lua binds on Hyper, one per line.
keys() {
  sed -n 's/^harpoon\.bind(hyper \.\. "\([A-Z0-9]*\)".*/\1/p' "$SRC/bindings.lua"
}

# Each key runs exactly the one harpoon binding (a Lua function), and the
# scratchpad is on Hyper+Escape alone.
bound() {
  for k in $(keys); do
    [ "$(lua "$PROBE" "bind:$HYPER + $k")" = "<dispatcher>" ] || return 1
  done
  [ "$(lua "$PROBE" "bind:$HYPER + ESCAPE")" = "<workspace.toggle_special>" ] &&
    [ "$(lua "$PROBE" "bind:SUPER + S")" = nil ]
}

in_place() {
  linked && [ "$(current)" = "$(block)" ] && bound && plugin_enabled
}

case "${1:-install}" in
check)
  in_place
  ;;
install)
  [ -f "$TARGET" ] && plugin_enabled ||
    { echo "$PLUGIN_ID isn't installed and enabled: add it to omarchy-plugins" >&2; exit 1; }
  mkdir -p "$(dirname "$CONF")"
  ln -sfn "$TARGET" "$ENGINE"
  touch "$CONF"
  # The file without the old block and its trailing blank lines, then the
  # current block.
  rest=$(awk -v b="$BEGIN" -v e="$END" '$0 == b { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$CONF")
  { printf '%s\n\n' "$rest"; block; } > "$CONF"
  in_place || { echo "the Hyper keys don't each run one harpoon binding after $CONF: something loaded later binds them" >&2; exit 1; }
  sig=$(live_instance)
  if [ -n "$sig" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl -q reload
    errors=$(HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl configerrors | grep -v '^[[:space:]]*$' || true)
    [ -z "$errors" ] || { echo "Hyprland reports config errors after the reload: $errors" >&2; exit 1; }
    live=$(HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl binds -j)
    for k in $(keys) ESCAPE; do
      got=$(printf '%s' "$live" | jq -r --argjson m "$MASK" --arg k "$k" \
        '[.[] | select(.modmask == $m and .key == $k) | .description] | join("|")')
      case "$got" in
      *"|"* | "") echo "the running Hyprland binds Hyper+$k to '$got', not one harpoon key" >&2; exit 1 ;;
      esac
    done
    # modmask 64: SUPER alone.
    printf '%s' "$live" | jq -e '[.[] | select(.modmask == 64 and .key == "S")] | length == 0' >/dev/null ||
      { echo "the running Hyprland still binds SUPER+S" >&2; exit 1; }
  else
    echo "Hyprland isn't reachable from here; the keys work at the next login."
  fi
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
