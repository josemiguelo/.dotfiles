#!/bin/sh
# The Omarchy bar itself, from the machine's opt-in, as what differs from a
# fresh install: its position and thickness, and optionally its background,
# its icon size and the stock widgets turned off, one key=value per argument
# ("omarchy-bar position=top size=24 background=glassy off=omarchy.workspaces";
# off= repeats). Where widgets sit and their settings are
# omarchy-bar-widgets'.
#
# The position and the background (opaque, glassy or none; Omarchy's default
# is opaque) are Omarchy's own settings (~/.config/omarchy/shell.json,
# bar.position and bar.background), set with `omarchy bar position` and
# `omarchy bar background`; a background the opt-in leaves out is left as it
# is. A glassy bar is see-through and Hyprland blurs what's behind it, while
# the bar-glassy toggle (~/.local/state/omarchy/toggles/hypr/bar-glassy.lua,
# a copy of Omarchy's default/hypr/toggles/bar-glassy.lua) is in place:
# `omarchy bar background` puts it there for glassy and removes it otherwise,
# so the check asks for both. The thickness is size-horizontal (top and bottom bars; size-vertical for
# left and right ones; Omarchy's default is 26) at font base-size 12, scaled
# with the font like Omarchy's; it lives in a block in
# ~/.config/omarchy/shell.toml, the machine-level file whose keys win over the
# theme's and which the shell reloads live. The icon size is icon-size, the
# size every bar icon is drawn at, glyph or SVG (Omarchy's default is 12), with
# icon-canvas raised to match: the icon is drawn at the smaller of the two.
# Both sit in the same block; left out, Omarchy's own sizes apply.
# `omarchy display text size` edits [font] there and leaves the rest. A [bar]
# table outside the block would make the file invalid TOML, so install refuses
# one. The bar's text follows the shell's [font] base-size.
#
# A stock widget turned off (omarchy.workspaces, when a plugin draws the
# workspaces) is disabled with `omarchy plugin disable`, which takes it off
# the bar.
# usage: omarchy-bar.sh [check] position=<top|bottom|left|right> size=<n> [background=<opaque|glassy|none>] [icon-size=<n>] [off=<widget-id>]...
set -eu

USAGE="usage: $0 [check] position=<top|bottom|left|right> size=<n> [background=<opaque|glassy|none>] [icon-size=<n>] [off=<widget-id>]..."
MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
POSITION="" SIZE="" BACKGROUND="" ICON_SIZE="" OFF=""
for arg in "$@"; do
  case "$arg" in
    position=*) POSITION=${arg#*=} ;;
    size=*) SIZE=${arg#*=} ;;
    background=*) BACKGROUND=${arg#*=} ;;
    icon-size=*) ICON_SIZE=${arg#*=} ;;
    off=?*) OFF="$OFF ${arg#*=}" ;;
    *) echo "$arg: not a key=value this script knows" >&2; echo "$USAGE" >&2; exit 2 ;;
  esac
done
case "$POSITION" in top | bottom) KEY=size-horizontal ;; left | right) KEY=size-vertical ;;
  *) echo "position must be top, bottom, left or right" >&2; echo "$USAGE" >&2; exit 2 ;; esac
case "$SIZE" in '' | *[!0-9]*) echo "size must be a whole number" >&2; exit 2 ;; esac
case "$BACKGROUND" in '' | opaque | glassy | none) ;; *) echo "background must be opaque, glassy or none" >&2; exit 2 ;; esac
case "$ICON_SIZE" in *[!0-9]*) echo "icon-size must be a whole number" >&2; exit 2 ;; esac

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/shell-ready.sh"
. "$HERE/lib/bar-widgets.sh"
shell_ready "$MODE"
TOML=$HOME/.config/omarchy/shell.toml
BEGIN="# >>> Managed by loadout (omarchy-bar)"
END="# <<< Managed by loadout (omarchy-bar)"

block() {
  echo "$BEGIN"
  echo "# The bar's thickness at font base-size 12 and its icon size (loadouts/private_dot_config/.omarchy/.loadout/omarchy-bar.sh)."
  echo "[bar]"
  echo "$KEY = $SIZE"
  if [ -n "$ICON_SIZE" ]; then
    echo "icon-size = $ICON_SIZE"
    echo "icon-canvas = $ICON_SIZE"
  fi
  echo "$END"
}

current() {
  [ -f "$TOML" ] || return 0
  awk -v b="$BEGIN" -v e="$END" '$0 == b { keep = 1 } keep { print } $0 == e { keep = 0 }' "$TOML"
}

# shell.toml without the block.
rest() {
  [ -f "$TOML" ] || return 0
  awk -v b="$BEGIN" -v e="$END" '$0 == b { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$TOML"
}

positioned() {
  [ -f "$BAR_JSON" ] && [ "$(jq -r '.bar.position // "top"' "$BAR_JSON")" = "$POSITION" ]
}

GLASS=${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/toggles/hypr/bar-glassy.lua

# No background named, or it's the one the bar has, with Hyprland's blur
# behind it exactly when it's glassy.
backed() {
  [ -n "$BACKGROUND" ] || return 0
  [ -f "$BAR_JSON" ] && [ "$(jq -r '.bar.background // "opaque"' "$BAR_JSON")" = "$BACKGROUND" ] || return 1
  if [ "$BACKGROUND" = glassy ]; then [ -f "$GLASS" ]; else [ ! -f "$GLASS" ]; fi
}

sized() {
  [ "$(current)" = "$(block)" ] && ! rest | grep -q '^[[:space:]]*\[bar\]'
}

# Every stock widget named off is disabled.
off() {
  for id in $OFF; do
    ! widget_enabled "$id" || return 1
  done
}

case "$MODE" in
check)
  positioned && backed && sized && off
  ;;
install)
  if rest | grep -q '^[[:space:]]*\[bar\]'; then
    echo "$TOML has its own [bar] table: move its keys into the opt-in, or remove it" >&2
    exit 1
  fi
  positioned || omarchy bar position "$POSITION"
  backed || omarchy bar background "$BACKGROUND" >/dev/null
  mkdir -p "$(dirname "$TOML")"
  others=$(rest)
  if [ -n "$others" ]; then
    { printf '%s\n\n' "$others"; block; } > "$TOML"
  else
    block > "$TOML"
  fi
  for id in $OFF; do
    if widget_enabled "$id"; then omarchy plugin disable "$id" >/dev/null; fi
  done
  positioned && backed && sized && off ||
    { echo "the bar's position, background, thickness, icon size or stock widgets turned off aren't what the opt-in names after install" >&2; exit 1; }
  ;;
esac
