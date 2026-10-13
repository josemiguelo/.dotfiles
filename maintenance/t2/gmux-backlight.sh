#!/bin/sh
# Keep the screen at the brightness you left it at, across suspend/hibernate,
# the screen turning off and on, and reboots.
#
# The panel's backlight on T2 MacBook Pros is the Apple gmux's
# (gmux_backlight, the device Omarchy's brightness keys drive).
#
# Sleep: waking from deep sleep resets the gmux to its own, bright default,
# but the driver doesn't push the level back, so the kernel's brightness value
# (what `brightnessctl` and Omarchy's OSD read) still says the old level while
# the panel shines brighter. The first brightness key then sets "old level ±
# 5%" on the hardware: a sudden jump down. A systemd sleep hook fixes it the
# way Omarchy fixes its own post-sleep quirks (/usr/lib/systemd/system-sleep/,
# the only directory systemd-sleep runs): on "post", write the kernel's value
# back to the device, which makes the driver send it to the gmux again. Tested
# by hand first: that write brings the panel straight back to its level.
#
# Screen off and on: the gmux also resets when the panel powers back up after
# a blank — seen right after waking, when Omarchy's lock screen blanks 5s in:
# the kernel's value stayed at the old level (logged every 0.2s) while the
# panel came back bright. Omarchy's wake step runs `omarchy-brightness-display
# on` whenever the screen comes back from a blank, so a wrapper for it — in the
# directory omarchy-command-overrides puts first on the session's PATH — runs
# Omarchy's command, then sends the level again, at once and once more a
# second later in case the gmux resets late.
#
# Reboots: systemd saves and restores every backlight through one udev rule
# (99-systemd.rules), which also imports path_id. The gmux sits on the PNP bus
# (/devices/pnp0/00:00), path_id can't place it and fails, and a failed import
# cancels the whole rule: no systemd tag, no systemd-backlight@ unit, so the
# level was never saved or restored. A rule of our own tags it and pulls the
# unit in without path_id, and names it (ID_PATH, which the saved file under
# /var/lib/systemd/backlight/ is named after) by its ACPI id. systemd's
# restore floor stays: never below 5%.
#
# Crashes: systemd-backlight saves only when its unit stops, at a clean
# shutdown. A hard reset (a GPU hang froze the session on 2026-10-13) skips
# that, and the next boots restored the level from the last clean shutdown
# hours before. So the wrapper also records the level in
# $XDG_STATE_HOME/gmux-backlight/level each time it's set (the brightness keys
# and the bar's slider both go through omarchy-brightness-display), and a
# hyprland.start listener in ~/.config/hypr/hyprland.lua (where Omarchy puts
# personal additions) sends it back at login, or the kernel's level when none
# was recorded yet. brightnessctl sets it through logind, no root needed.
#
# Timing: the gmux resets to its bright default whenever the panel powers
# back up (the login's first modeset, the wake after a lock blank), a moment
# after the command that powers it returns. A single resend right away lands
# too early and one a second later leaves a second of glare, so both the login
# and the wrapper's `on` resend every 0.1s for a few seconds.
#
# Installing only uses sudo for what actually changes (the hook and the rule
# are root's; the wrapper and the listener are yours).
# Modes: `check` / `install` (default).
set -eu

HOOK=/usr/lib/systemd/system-sleep/t2-gmux-backlight
RULE=/etc/udev/rules.d/99-gmux-backlight.rules
DEVICE=/sys/class/backlight/gmux_backlight
UNIT=systemd-backlight@backlight:gmux_backlight.service
DISPLAY_COMMAND=omarchy-brightness-display
HERE="$(cd "$(dirname "$0")" && pwd)"
PROBE=$HERE/../omarchy/lib/hypr-option.lua
. "$HERE/../omarchy/lib/omarchy-overrides-lib.sh"
WRAPPER=$OVERRIDES_DIR/$DISPLAY_COMMAND
CONF=$HOME/.config/hypr/hyprland.lua
BEGIN="-- >>> Managed by loadout (t2-gmux-backlight)"
END="-- <<< Managed by loadout (t2-gmux-backlight)"

hook_text() {
  cat <<'HOOK_EOF'
#!/bin/sh
# Managed by loadout (t2-gmux-backlight): after suspend/hibernate, send the
# kernel's brightness value back to the gmux, which wakes at its own bright
# default without it.
[ "$1" = post ] || exit 0
device=/sys/class/backlight/gmux_backlight
if [ -w "$device/brightness" ] && level=$(cat "$device/brightness"); then
  echo "$level" > "$device/brightness"
fi
exit 0
HOOK_EOF
}

rule_text() {
  cat <<'RULE_EOF'
# Managed by loadout (t2-gmux-backlight): save and restore the gmux backlight
# across reboots. 99-systemd.rules' backlight rule imports path_id, which
# fails for this PNP-bus device and cancels the rule, so tag it here instead.
SUBSYSTEM=="backlight", KERNEL=="gmux_backlight", ENV{ID_PATH}="acpi-APP000B", TAG+="systemd", ENV{SYSTEMD_WANTS}+="systemd-backlight@backlight:$name.service"
RULE_EOF
}

wrapper_text() {
  cat <<WRAPPER_EOF
#!/bin/bash
# Managed by loadout (t2-gmux-backlight): after Omarchy's \`on\`, send the
# kernel's brightness to the gmux again — it resets to its own bright default
# when the panel powers back up after a blank. Everything else is Omarchy's.
"$OMARCHY_BIN/$DISPLAY_COMMAND" "\$@"
status=\$?

resend() {
  local device=/sys/class/backlight/gmux_backlight level
  [[ -e \$device/brightness ]] && level=\$(< "\$device/brightness") &&
    brightnessctl -q -d gmux_backlight set "\$level"
}

# The level as just set, for the login to send back after a crash skipped
# systemd-backlight's save. Not for on/off: those leave the level alone.
record() {
  local device=/sys/class/backlight/gmux_backlight
  local dir=\${XDG_STATE_HOME:-\$HOME/.local/state}/gmux-backlight level
  [[ -e \$device/brightness ]] && level=\$(< "\$device/brightness") &&
    [[ \$level -gt 0 ]] && mkdir -p "\$dir" &&
    printf '%s\\n' "\$level" > "\$dir/level.tmp" && mv "\$dir/level.tmp" "\$dir/level"
}

for arg in "\$@"; do
  case \$arg in
  on)
    resend
    (for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do sleep 0.1; resend; done) >/dev/null 2>&1 &
    exit \$status
    ;;
  off) exit \$status ;;
  esac
done
(( \$# == 0 )) || record
exit \$status
WRAPPER_EOF
}

block() {
  cat <<'BLOCK_EOF'
-- >>> Managed by loadout (t2-gmux-backlight)
-- Send the brightness recorded by the omarchy-brightness-display wrapper (or
-- the kernel's, before anything was recorded) back to the gmux at login: a
-- crash skips systemd-backlight's save at shutdown, and the login's first
-- modeset resets the gmux to its default. Every 0.1s for 3s, to catch that
-- reset whenever it lands (maintenance/t2/gmux-backlight.sh).
hl.on("hyprland.start", function()
  hl.exec_cmd([[level=$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/gmux-backlight/level" 2>/dev/null || cat /sys/class/backlight/gmux_backlight/brightness) || exit 0; i=0; while [ $i -lt 30 ]; do brightnessctl -q -d gmux_backlight set "$level"; sleep 0.1; i=$((i + 1)); done]])
end)
-- <<< Managed by loadout (t2-gmux-backlight)
BLOCK_EOF
}

current() {
  [ -f "$CONF" ] || return 0
  awk -v b="$BEGIN" -v e="$END" '$0 == b { keep = 1 } keep { print } $0 == e { keep = 0 }' "$CONF"
}

listener_ready() {
  [ "$(current)" = "$(block)" ]
}

wrapper_ready() {
  [ -x "$WRAPPER" ] && [ "$(cat "$WRAPPER")" = "$(wrapper_text)" ] && override_active "$DISPLAY_COMMAND"
}

hook_ready() {
  [ -x "$HOOK" ] && [ "$(cat "$HOOK")" = "$(hook_text)" ]
}

# The rule is in place and udev applied it to the device.
rule_ready() {
  [ -f "$RULE" ] && [ "$(cat "$RULE")" = "$(rule_text)" ] || return 1
  [ -e "$DEVICE" ] || return 0
  props=$(udevadm info --query=property "$DEVICE")
  printf '%s\n' "$props" | grep -q '^TAGS=.*:systemd:' &&
    printf '%s\n' "$props" | grep -qx "SYSTEMD_WANTS=.*$UNIT.*"
}

case "${1:-install}" in
check)
  hook_ready && rule_ready && wrapper_ready && listener_ready
  ;;
install)
  if ! hook_ready; then
    hook_text | sudo tee "$HOOK" >/dev/null
    sudo chmod 755 "$HOOK"
  fi
  if ! rule_ready; then
    rule_text | sudo tee "$RULE" >/dev/null
    sudo udevadm control --reload
    if [ -e "$DEVICE" ]; then
      # Re-run the rules for the device now, so systemd picks the unit up
      # without waiting for the next boot.
      sudo udevadm trigger --action=add --settle "$DEVICE"
    fi
  fi
  mkdir -p "$OVERRIDES_DIR"
  wrapper_text > "$WRAPPER"
  chmod 755 "$WRAPPER"
  if ! listener_ready; then
    rest=$(awk -v b="$BEGIN" -v e="$END" '$0 == b { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$CONF" 2>/dev/null || true)
    { printf '%s\n\n' "$rest"; block; } > "$CONF"
  fi
  hook_ready || { echo "$HOOK not in place after install" >&2; exit 1; }
  rule_ready || { echo "udev doesn't tag $DEVICE for $UNIT after install" >&2; exit 1; }
  wrapper_ready || { echo "the session doesn't run $WRAPPER: is omarchy-command-overrides installed?" >&2; exit 1; }
  listener_ready || { echo "the hyprland.start listener isn't in $CONF after install" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
