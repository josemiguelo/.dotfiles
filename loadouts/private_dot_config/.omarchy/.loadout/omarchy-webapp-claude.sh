#!/bin/sh
# Claude (claude.ai) as an Omarchy web app (its own app window), with
# Omarchy's own omarchy-webapp-install. Hyper+C toggles it as an overlay
# (.hypr/.loadout/omarchy-harpoon/bindings.lua).
# Modes: `check` / `install` (default).
set -eu

DESKTOP="$HOME/.local/share/applications/Claude.desktop"
URL=https://claude.ai/
ICON=https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/claude-ai.png

ready() {
  grep -q "^Exec=omarchy-launch-webapp.*claude\.ai" "$DESKTOP" 2>/dev/null
}

case "${1:-install}" in
check)
  ready
  ;;
install)
  omarchy-webapp-install Claude "$URL" "$ICON"
  ready || { echo "Claude web app not in place after install" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
