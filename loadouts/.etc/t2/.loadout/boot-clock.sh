#!/bin/sh
# Keep the T2 Mac's hardware clock set.
#
# The MacBookPro16,1 has one real, battery-backed RTC living in the EC. Linux
# sees it up to three times:
#
#   rtc_cmos  legacy CMOS ports, rtc0. What the kernel reads at boot
#             (hctosys=1), but writes to it are discarded by the firmware —
#             which is where the kernel's 11-minute NTP writeback goes, so it
#             never took effect.
#   t2smc     KaiT2en's SMC driver (APP0001) registers the clock as an RTC it
#             can read and write. On linux-omarchy it loads from the initramfs
#             and takes rtc1 (reading the same time as rtc0).
#   acpi-tad  the ACPI Time and Alarm Device \_SB.PCI0.LPCB.ARTC (ACPI000E).
#             Its _SRT method writes the clock; reading it back returns -EIO
#             on a stock kernel (Apple's _GRT fills the ACPI validity byte
#             from an EC field it declares as padding, so acpi_tad throws the
#             timestamp away). It was rtc1 under linux-t2, rtc2 now.
#
# Before, nothing in Linux had ever set this clock. It ticked accurately from a
# cold-boot zero, every boot read back 1970-01-28, and systemd bumped that to
# its own build date — leaving the machine ~6 weeks in the past until chrony
# synced. Journal timestamps were wrong and PackageKit's reboot-to-install
# offline updates aborted before rpm ever opened the database.
#
# A shutdown unit writes the system time back through t2smc, or the ACPI TAD
# where t2smc isn't loaded. Which rtcN each is depends on the kernel and load
# order, so the unit runs a helper that picks the device by name at shutdown,
# and neither the unit nor the helper names a number. Install also sets the
# clock right away.
set -eu

UNIT=/etc/systemd/system/sync-hwclock.service
HELPER=/usr/local/sbin/t2-hwclock-save

helper_text() {
  cat <<'EOF'
#!/bin/sh
# Managed by loadout (t2-boot-clock): write the system time to the T2 Mac's EC
# clock, through t2smc (APP0001) or else the ACPI TAD (ACPI000E), picked by
# name since their rtcN numbers follow the kernel and load order.
for name in APP0001 ACPI000E; do
  for rtc in /sys/class/rtc/rtc*; do
    grep -q "$name" "$rtc/name" 2>/dev/null || continue
    exec /usr/sbin/hwclock --rtc="/dev/${rtc##*/}" --systohc
  done
done
echo "t2-hwclock-save: no EC clock (t2smc or ACPI TAD) here" >&2
exit 1
EOF
}

unit_text() {
  cat <<EOF
[Unit]
Description=Write system time to the EC hardware clock at shutdown
DefaultDependencies=no
After=local-fs.target
Before=shutdown.target
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/true
ExecStop=$HELPER

[Install]
WantedBy=multi-user.target
EOF
}

# Apple-only, and only with an EC clock device: elsewhere an ACPI000E device
# is a normal TAD next to a working RTC, and there is nothing to fix.
applicable() {
  [ "$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)" = "Apple Inc." ] || return 1
  grep -q -E 'APP0001|ACPI000E' /sys/class/rtc/rtc*/name 2>/dev/null
}

case "${1:-install}" in
  check)
    applicable || exit 0
    [ -x "$HELPER" ] && [ "$(cat "$HELPER")" = "$(helper_text)" ]
    [ "$(cat "$UNIT" 2>/dev/null)" = "$(unit_text)" ]
    systemctl is-enabled --quiet sync-hwclock.service
    ;;
  install)
    if ! applicable; then
      echo "No Apple EC clock here; nothing to do."
      exit 0
    fi
    if ! { [ -x "$HELPER" ] && [ "$(cat "$HELPER")" = "$(helper_text)" ]; }; then
      helper_text | sudo install -D -m 755 /dev/stdin "$HELPER"
    fi
    if [ "$(cat "$UNIT" 2>/dev/null)" != "$(unit_text)" ]; then
      unit_text | sudo tee "$UNIT" >/dev/null
      sudo systemctl daemon-reload
    fi
    sudo systemctl enable --now sync-hwclock.service
    # Set it now, so the fix applies without waiting for a shutdown.
    sudo "$HELPER"
    ;;
  *) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
