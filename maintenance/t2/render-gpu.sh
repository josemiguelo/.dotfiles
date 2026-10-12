#!/bin/sh
# Hyprland renders on the GPU that drives the built-in panel.
#
# The MacBookPro16,1 has an Intel iGPU and an AMD dGPU, and the Apple gmux
# wires the panel (eDP) to one of them: the AMD one, as the machine boots.
# Hyprland (aquamarine) takes the first DRM card it enumerates as its primary
# renderer, which is the Intel one, so every frame — the cursor's included —
# was drawn on Intel and copied across to the AMD card for scanout. The
# cursor lagged and typing felt slow; the Hyprland log said "gpu
# /dev/dri/card1 becomes primary drm" (i915) while eDP-1 hung off card2
# (amdgpu). AQ_DRM_DEVICES names the primary.
#
# Nothing here names a card or a PCI address: card numbers follow probe order,
# and the gmux can put the panel on either GPU (force_igd). The block finds,
# at every login, the card whose eDP connector is connected, and leaves
# AQ_DRM_DEVICES unset when there's none. It lives in
# ~/.config/uwsm/env-hyprland, which uwsm sources before starting Hyprland —
# Hyprland's own config is read after aquamarine has picked its GPU. Only
# the panel's card is listed: the Thunderbolt ports are wired to the AMD card
# too. Install rewrites the block between its markers; takes effect at the
# next login. Modes: `check` / `install` (default).
set -eu

ENV_FILE=${XDG_CONFIG_HOME:-$HOME/.config}/uwsm/env-hyprland
BEGIN="# >>> Managed by loadout (t2-render-gpu)"
END="# <<< Managed by loadout (t2-render-gpu)"

block() {
  cat <<BLOCK_EOF
$BEGIN
# Hyprland renders on the GPU the built-in panel is wired to, picked at login
# (maintenance/t2/render-gpu.sh): left alone it renders on the Intel iGPU and
# copies every frame to the AMD card driving the panel, which lags.
for status in /sys/class/drm/card*-eDP-*/status; do
  [ "\$(cat "\$status" 2>/dev/null)" = connected ] || continue
  card=\${status#/sys/class/drm/}
  export AQ_DRM_DEVICES="/dev/dri/\${card%%-*}"
  break
done
unset status card
$END
BLOCK_EOF
}

# The file without the block.
rest() {
  [ -f "$ENV_FILE" ] || return 0
  awk -v b="$BEGIN" -v e="$END" '$0 == b { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$ENV_FILE"
}

# The block, exactly, between its markers.
ready() {
  [ -f "$ENV_FILE" ] &&
    [ "$(awk -v b="$BEGIN" -v e="$END" '$0 == b { on = 1 } on { print } $0 == e { on = 0 }' "$ENV_FILE")" = "$(block)" ]
}

case "${1:-install}" in
check)
  ready
  ;;
install)
  if ! ready; then
    mkdir -p "$(dirname "$ENV_FILE")"
    others=$(rest)
    { [ -z "$others" ] || printf '%s\n\n' "$others"; block; } > "$ENV_FILE"
  fi
  ready || { echo "$ENV_FILE doesn't hold the block after install" >&2; exit 1; }
  device=$(env -i sh -c ". '$ENV_FILE'; echo \"\${AQ_DRM_DEVICES:-}\"")
  if [ -n "$device" ]; then
    echo "Hyprland renders on $device from the next login."
  else
    echo "No connected built-in panel found; Hyprland keeps its own choice." >&2
  fi
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
