#!/bin/sh
# This repo's own bar widgets, one plugin id per argument: each is
# omarchy-bar/plugins/<id>, copied whole into ~/.config/omarchy/plugins/<id>
# and enabled (where it sits is omarchy-bar-widgets'). They draw their icon
# with Omarchy's BarIconButton, so it follows the bar's icon size like every
# other.
# usage: omarchy-bar-own-widgets.sh [check] <plugin-id>...
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
[ $# -gt 0 ] || { echo "usage: $0 [check] <plugin-id>..." >&2; exit 2; }

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC=$HERE/omarchy-bar/plugins
. "$HERE/lib/shell-ready.sh"
. "$HERE/lib/bar-widgets.sh"
shell_ready "$MODE"
PLUGINS=$HOME/.config/omarchy/plugins

for id in "$@"; do
  [ -f "$SRC/$id/manifest.json" ] || { echo "$id: no widget at $SRC/$id" >&2; exit 2; }
done

copied() {
  [ -d "$PLUGINS/$1" ] && diff -r "$SRC/$1" "$PLUGINS/$1" >/dev/null
}

in_place() {
  for id in "$@"; do
    copied "$id" && widget_enabled "$id" || return 1
  done
}

case "$MODE" in
check)
  in_place "$@"
  ;;
install)
  changed=no
  mkdir -p "$PLUGINS"
  for id in "$@"; do
    copied "$id" && continue
    # The folder is swapped in whole, so no file of an earlier version stays.
    stage=$(mktemp -d "$PLUGINS/.omarchy-bar-own-widgets.XXXXXX")
    cp -R "$SRC/$id/." "$stage/"
    rm -rf -- "${PLUGINS:?}/$id"
    mv "$stage" "$PLUGINS/$id"
    changed=yes
  done
  omarchy-shell shell rescanPlugins >/dev/null
  for id in "$@"; do
    tries=0
    until widget_enabled "$id" || omarchy plugin enable "$id" >/dev/null 2>&1; do
      tries=$((tries + 1))
      [ "$tries" -lt 20 ] || { echo "couldn't enable $id (is omarchy-shell running?)" >&2; exit 1; }
      sleep 0.5
    done
  done
  if [ "$changed" = yes ]; then
    # A loaded plugin keeps its old QML until the shell restarts. Quickshell
    # can crash when killed mid hot-reload, so the files settle first.
    sleep 3
    omarchy restart shell >/dev/null 2>&1 || echo "restart the Omarchy shell to load the new widgets (omarchy restart shell)" >&2
    shell_ready || true
  fi
  in_place "$@" || { echo "the widgets aren't installed and enabled after install" >&2; exit 1; }
  ;;
esac
