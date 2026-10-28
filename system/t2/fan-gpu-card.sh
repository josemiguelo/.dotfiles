#!/bin/sh
# t2fanrd reads the GPU's temperature from a hardcoded path,
# /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input, and with no reading
# there it drives both fans at their maximum all the time. On the
# MacBookPro16,1 card0 never was the AMD dGPU (the only card with that
# sensor; the boots logged on 2026-10-13 all had simpledrm 0, i915 1,
# amdgpu 2):
#
#   - simpledrm, built in, takes DRM minor 0 for the boot framebuffer and
#     gives it up when a real driver takes over, so card0 disappears.
#   - Without it, i915 probes first (the kms hook loads both from the
#     initramfs), and the Intel iGPU has no hwmon temperature either.
#
# So: no simpledrm (initcall_blacklist, through a Limine drop-in), and the
# sensor's GPU driver loaded explicitly from the initramfs, ahead of udev's
# i915. Nothing names a driver or card: the GPU is the display device that
# has the temperature sensor (amdgpu on these Macs), and apple-gmux goes in
# front of it when the machine has a gmux, as it already loaded first:
# vga_switcheroo wants the gmux registered before the GPUs. A Mac with no
# such GPU (Intel only) gets nothing, and its check passes. The panel is
# wired to the dGPU, so the splash and the LUKS prompt come up there once it
# probes; render-gpu.sh names no card number, so it follows the renumbering.
#
# limine-mkinitcpio rebuilds the UKI (initramfs and command line both) and
# the boot entries. /boot isn't readable unprivileged, so check asks the
# booted system instead: the parameter is on the command line and card0 has
# the sensor t2fanrd reads. Takes effect at the next boot.
# Modes: `check` / `install` (default).
set -eu

LIMINE_CONF=/etc/limine-entry-tool.d/t2-fan-gpu-card.conf
LIMINE_WANT='# loadout t2-fan-gpu-card: no simpledrm, so card0 is a real GPU (t2fanrd)
KERNEL_CMDLINE[default]+=" initcall_blacklist=simpledrm_platform_driver_init"'
MKINITCPIO_CONF=/etc/mkinitcpio.conf.d/t2-fan-gpu-card.conf

# The driver of the display device (PCI class 03) with the temperature
# sensor t2fanrd reads; empty when there's none. Read from the running
# system, so that driver has to be loaded, as it is at every boot here.
sensor_driver() {
  for dev in /sys/bus/pci/devices/*; do
    case $(cat "$dev/class") in 0x03*) ;; *) continue ;; esac
    ls "$dev"/hwmon/hwmon*/temp1_input >/dev/null 2>&1 || continue
    [ -e "$dev/driver" ] || continue
    basename "$(readlink -f "$dev/driver")"
    return
  done
}

DRIVER=$(sensor_driver)
GMUX=
[ -d /sys/module/apple_gmux ] && GMUX='apple-gmux '
MKINITCPIO_WANT="# loadout t2-fan-gpu-card: $DRIVER probes first and takes card0 (t2fanrd)
MODULES+=($GMUX$DRIVER)"

files_ok() {
  [ "$(cat "$LIMINE_CONF" 2>/dev/null)" = "$LIMINE_WANT" ] &&
    [ "$(cat "$MKINITCPIO_CONF" 2>/dev/null)" = "$MKINITCPIO_WANT" ]
}

booted_ok() {
  grep -qw initcall_blacklist=simpledrm_platform_driver_init /proc/cmdline &&
    ls /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input >/dev/null 2>&1
}

if [ -z "$DRIVER" ]; then
  [ "${1:-install}" = check ] || echo "t2-fan-gpu-card: no GPU with a temperature sensor here, nothing to do"
  exit 0
fi

case "${1:-install}" in
  check)
    files_ok
    booted_ok
    ;;
  install)
    rebuild=no
    if [ "$(cat "$LIMINE_CONF" 2>/dev/null)" != "$LIMINE_WANT" ]; then
      printf '%s\n' "$LIMINE_WANT" | sudo tee "$LIMINE_CONF" >/dev/null
      rebuild=yes
    fi
    if [ "$(cat "$MKINITCPIO_CONF" 2>/dev/null)" != "$MKINITCPIO_WANT" ]; then
      printf '%s\n' "$MKINITCPIO_WANT" | sudo tee "$MKINITCPIO_CONF" >/dev/null
      rebuild=yes
    fi
    # The image that booted didn't carry them: rebuild it too.
    booted_ok || rebuild=yes
    if [ "$rebuild" = yes ]; then
      sudo limine-mkinitcpio
      echo "t2-fan-gpu-card: takes effect at the next boot"
    fi
    ;;
  *) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
