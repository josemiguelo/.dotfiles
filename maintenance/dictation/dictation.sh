#!/bin/sh
# Voxtype dictation, set up the way Omarchy's own installer
# (omarchy-voxtype-install) does it, minus its question: that installer opens
# with a `gum confirm` ("Install Voxtype + AI model (~150MB)?") that nothing
# can answer in advance, which stopped an unattended setup-new-machine. So the
# steps it runs after that confirm are here, as of Omarchy's installer in
# October 2026:
#
#   omarchy-pkg-add wtype voxtype-bin      loadout's own programs (voxtype,
#                                          wtype), installed before this runs
#   cp default/voxtype/config.toml         here, only when there's no config
#                                          yet, so local edits survive
#   voxtype setup --download               here: the speech model (~150MB),
#                                          only when it's missing
#   voxtype setup gpu --enable             omarchy-dictation-gpu, with sudo
#   voxtype setup systemd                  here
#   hyprctl reload; omarchy-restart-shell  here
#
# Then F9 is hold-to-dictate, Super+Ctrl+X toggles. A later Omarchy may add a
# step to its installer: compare with `cat $(command -v omarchy-voxtype-install)`.
# Modes: `check` / `install` (default).
set -eu

CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/voxtype/config.toml
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../omarchy/lib/hypr-live.sh"
. "$HERE/../omarchy/lib/shell-ready.sh"

ready() {
  command -v voxtype >/dev/null 2>&1 &&
    [ -f "$CONFIG" ] &&
    systemctl --user -q is-enabled voxtype.service 2>/dev/null
}

case "${1:-install}" in
check)
  ready
  ;;
install)
  command -v voxtype >/dev/null 2>&1 || { echo "voxtype isn't installed (programs.voxtype)" >&2; exit 1; }
  if [ ! -f "$CONFIG" ]; then
    mkdir -p "$(dirname "$CONFIG")"
    cp "${OMARCHY_PATH:-/usr/share/omarchy}/default/voxtype/config.toml" "$CONFIG"
  fi
  voxtype setup --download --no-post-install
  voxtype setup systemd
  sig=$(live_instance)
  if [ -n "$sig" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl -q reload
    omarchy-restart-shell >/dev/null 2>&1 || true
    shell_ready || true
  fi
  ready || { echo "dictation isn't set up: no $CONFIG, or voxtype.service isn't enabled" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
