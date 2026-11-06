#!/bin/sh
# Voxtype dictation, set up the way Omarchy's own installer
# (omarchy-install-dictation-voxtype, omarchy-voxtype-install before 4.5) does
# it, minus its question: when voxtype is missing it opens with a `gum
# confirm` that nothing can answer in advance, which stopped an unattended
# setup-new-machine. So its steps are here, as of Omarchy 4.5's installer:
#
#   omarchy-pkg-add wtype voxtype-bin      loadout's own programs (voxtype,
#                                          wtype), installed before this runs
#   cp default/voxtype/config.toml         here, only when there's no config
#                                          yet, so local edits survive
#   voxtype setup gpu --enable             omarchy-dictation-gpu, with sudo
#   voxtype setup --download               here: the speech model (~150MB),
#                                          only when it's missing
#   voxtype setup systemd                  here, and the service enabled
#   omarchy-dictation-use voxtype          here (4.5 on): Voxtype as the
#                                          dictation backend Omarchy's keys run
#   hyprctl reload; omarchy-restart-shell  here
#
# Then (4.5 on) Alt+Space toggles and Right Alt is hold-to-dictate; a 4.5
# migration keeps F9 and Super+Ctrl+X for machines that had dictation before.
# A later Omarchy may add a step to its installer: compare with
# `cat $(command -v omarchy-install-dictation-voxtype)`.
# Modes: `check` / `install` (default).
set -eu

CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/voxtype/config.toml
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../.omarchy/.loadout/lib/hypr-live.sh"
. "$HERE/../../.omarchy/.loadout/lib/shell-ready.sh"

# Omarchy 4.5 on picks the backend its dictation keys run; before, there was
# only Voxtype.
backend_chosen() {
  command -v omarchy-dictation-use >/dev/null 2>&1 || return 0
  [ "$(omarchy-default-dictation 2>/dev/null)" = voxtype ]
}

ready() {
  command -v voxtype >/dev/null 2>&1 &&
    [ -f "$CONFIG" ] &&
    systemctl --user -q is-enabled voxtype.service 2>/dev/null &&
    backend_chosen
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
  systemctl --user enable --now voxtype.service
  backend_chosen || omarchy-dictation-use voxtype
  sig=$(live_instance)
  if [ -n "$sig" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl -q reload
    omarchy-restart-shell >/dev/null 2>&1 || true
    shell_ready || true
  fi
  ready || { echo "dictation isn't set up: no $CONFIG, voxtype.service isn't enabled, or Voxtype isn't Omarchy's dictation backend" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
