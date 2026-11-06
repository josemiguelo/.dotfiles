#!/bin/sh
# Where installed bar widgets (omarchy-plugins, omarchy-bar-own-widgets) sit, from
# the machine's multi-line opt-in, one widget per line:
# "<id> <section> <before|after> <neighbour-id>"
# ("io.github.sumdahl.media right after omarchy.tray"; the sections are
# Omarchy's: left, centerBegin, center, centerEnd, tray, right), or
# "<id> <section> at <index>" for a widget with no neighbour to sit by (the
# clock, alone in center, placed to get its settings). Placement is
# Omarchy's own bar layout (~/.config/omarchy/shell.json), changed with
# `omarchy bar move`, or `omarchy bar put` for a widget off the bar (enabled
# by its plugins[] entry alone, like Keystroke's menu). A widget with
# omarchy-bar/settings/<id>.json gets those settings set
# with `omarchy bar set` into its entry (keys the file doesn't list are left
# as they are; lib/bar-widgets.sh). The check:
# each widget enabled, right before/after its neighbour (or at its index) in
# that section, and every listed setting at its value. Widgets are placed in
# the opt-in's order, so a neighbour is one already in the section (stock, or
# placed by an earlier line).
# usage: omarchy-bar-widgets.sh [check] "<id> <section> <before|after|at> <neighbour|index>"...
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
[ $# -gt 0 ] || { echo "usage: $0 [check] \"<id> <section> <before|after|at> <neighbour|index>\"..." >&2; exit 2; }

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/shell-ready.sh"
. "$HERE/lib/plugin-update-hint.sh"
. "$HERE/lib/bar-widgets.sh"
shell_ready "$MODE"

# placed <id> <section> <before|after|at> <neighbour|index>
placed() {
  [ -f "$BAR_JSON" ] && jq -e --arg id "$1" --arg s "$2" --arg rel "$3" --arg n "$4" '
    [.bar.layout[$s][]?.id] as $ids
    | ($ids | index($id)) as $i
    | if $rel == "at" then $i == ($n | tonumber)
      else ($ids | index($n)) as $j
        | $i != null and $j != null and (if $rel == "before" then $i + 1 == $j else $i == $j + 1 end)
      end' "$BAR_JSON" >/dev/null
}

# The arguments as one widget per line: loadout splits a multi-line opt-in
# on whitespace, so the words are regrouped in fours.
lines() {
  printf '%s\n' "$@" | tr -s ' \t' '\n\n' | awk 'NF { w[++n] = $0 }
    END { if (n % 4) { print "BAD"; exit } for (i = 1; i <= n; i += 4) print w[i], w[i+1], w[i+2], w[i+3] }'
}

[ "$(lines "$@" | head -1)" != BAD ] ||
  { echo "each widget needs four words: <id> <section> <before|after|at> <neighbour|index>" >&2; exit 2; }

failed=0
lines "$@" | {
  while read -r id section rel neighbour; do
    case "$rel" in
      before | after) ;;
      at) case "$neighbour" in '' | *[!0-9]*) echo "$id: at <index>, not '$neighbour'" >&2; exit 2 ;; esac ;;
      *) echo "$id: <before|after|at>, not '$rel'" >&2; exit 2 ;;
    esac
    if [ "$rel" = at ]; then flag=--index; else flag=--$rel; fi
    settings=$HERE/omarchy-bar/settings/$id.json
    if [ "$MODE" = install ]; then
      widget_on_bar "$id" || omarchy bar put "$id" --section "$section" "$flag" "$neighbour" >/dev/null || true
      widget_enabled "$id" || { echo "$id isn't installed and enabled" >&2; failed=1; continue; }
      # A neighbour not in the section yet fails the move; the check below says so.
      placed "$id" "$section" "$rel" "$neighbour" ||
        omarchy bar move "$id" --section "$section" "$flag" "$neighbour" >/dev/null || true
      widget_configured "$id" "$settings" || widget_configure "$id" "$settings"
    fi
    if ! { widget_enabled "$id" && placed "$id" "$section" "$rel" "$neighbour" && widget_configured "$id" "$settings"; }; then
      if [ "$MODE" = install ]; then
        echo "$id isn't at $section, $rel $neighbour, with its settings after install" >&2
        plugin_update_hint "$id"
      fi
      failed=1
    fi
  done
  exit "$failed"
}
