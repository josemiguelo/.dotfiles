#!/bin/sh
# The T2 Wi-Fi/Bluetooth firmware (docs/t2-macbook.md). Only macOS ships it,
# and it can't go into this public repo. Two sources, in order:
#
# 1. The macOS volume, through apple-bcm-firmware-fetcher (Omarchy's
#    installer, install/hardware/apple/fix-t2.sh): it mounts the volume
#    read-only with the APFS driver (linux-apfs-rw-dkms on linux-omarchy) and
#    copies the firmware to /lib/firmware/brcm, listing what it copied in
#    $STATE. fix-t2.sh also enables t2-wifi-firmware.service, which runs it on
#    the installed system's boots until $STATE exists: the run during an ISO
#    install happens in a chroot that can't load the installed kernel's APFS
#    driver.
# 2. With no macOS volume: apple-bcm-firmware 14.0-1, a package that has left
#    the repos and conflicts with the fetcher. It is a document in 1Password
#    (Personal vault, titled by its file name), and a copy verified against
#    SHA256 below is kept at $COPY, outside the pacman cache paccache trims.
#
# Whichever package provides the firmware stays explicitly installed: from
# Omarchy 4.5 `omarchy-update` removes orphans without asking.
#
# check: the fetcher installed explicitly with its firmware fetched, or the
# fallback package installed explicitly with all its files and the copy in
# place. It never asks 1Password anything.
# install, only when check fails: the fetcher when a macOS volume is there
# (installed if missing, replacing the fallback package), else the fallback
# (from the pacman cache's copy or 1Password, which needs a network: USB
# tethering or a USB Ethernet adapter); then the Wi-Fi driver reloads.
# Modes: `check` / `install` (default).
set -eu

FETCHER=apple-bcm-firmware-fetcher
STATE=/var/lib/apple-bcm-firmware-fetcher/installed-files
PACKAGE=apple-bcm-firmware
FILE=apple-bcm-firmware-14.0-1-any.pkg.tar.zst
SHA256=f2cd47d9e3fb9658f16997b2d9ace3033b57925b8c6ddd86ccc3d07d0c3e9559
CACHE=/var/cache/pacman/pkg/$FILE
COPY=/var/lib/t2-bcm-firmware/$FILE
VAULT=Personal

verified() {
  [ -f "$1" ] && [ "$(sha256sum "$1" | cut -d' ' -f1)" = "$SHA256" ]
}

explicit() {
  pacman -Qqe "$1" >/dev/null 2>&1
}

fetched() {
  explicit "$FETCHER" && [ -s "$STATE" ]
}

fallback_ok() {
  pacman -Qk "$PACKAGE" >/dev/null 2>&1 && explicit "$PACKAGE" && verified "$COPY"
}

# The macOS volume's APFS container on the internal disk, as the fetcher looks
# for it.
macos_volume() {
  lsblk -rno PATH,FSTYPE 2>/dev/null | awk '$1 ~ /nvme0n1/ && $2 == "apfs" { found = 1 } END { exit !found }'
}

reload_wifi() {
  # brcmfmac read no firmware when it loaded; loading it again reads it now.
  # brcmfmac_wcc holds brcmfmac, so it goes first (as the fetcher's own reload
  # does); otherwise removing brcmfmac fails with "in use".
  sudo modprobe -r brcmfmac_wcc 2>/dev/null || true
  sudo modprobe -r brcmfmac 2>/dev/null && sudo modprobe brcmfmac 2>/dev/null ||
    echo "reboot for the Wi-Fi to pick up the firmware" >&2
}

from_macos() {
  if pacman -Q "$PACKAGE" >/dev/null 2>&1; then
    sudo pacman -R --noconfirm "$PACKAGE"
  fi
  pacman -Q "$FETCHER" >/dev/null 2>&1 || omarchy-pkg-add "$FETCHER"
  explicit "$FETCHER" || sudo pacman -D --asexplicit "$FETCHER" >/dev/null
  # Its post-install fetches already when it can; run it until it has.
  [ -s "$STATE" ] || sudo "$FETCHER"
  reload_wifi
  fetched || { echo "$FETCHER didn't fetch the firmware from the macOS volume" >&2; exit 1; }
}

from_fallback() {
  if ! verified "$COPY"; then
    if verified "$CACHE"; then
      source=$CACHE
    else
      op vault list >/dev/null 2>&1 || {
        echo "no macOS volume and no copy of $FILE here, and 1Password isn't unlocked for the CLI: unlock the app (and approve its prompt), then run this again" >&2
        exit 1
      }
      tmp=$(mktemp -d)
      trap 'rm -rf "$tmp"' EXIT
      op document get "$FILE" --vault "$VAULT" --out-file "$tmp/$FILE" >/dev/null
      verified "$tmp/$FILE" || { echo "the $FILE in 1Password doesn't match its SHA256" >&2; exit 1; }
      source=$tmp/$FILE
    fi
    sudo install -D -m 644 "$source" "$COPY"
  fi
  if ! pacman -Qk "$PACKAGE" >/dev/null 2>&1; then
    if pacman -Q "$FETCHER" >/dev/null 2>&1; then
      sudo pacman -R --noconfirm "$FETCHER"
    fi
    sudo pacman -U --noconfirm "$COPY"
    reload_wifi
  fi
  explicit "$PACKAGE" || sudo pacman -D --asexplicit "$PACKAGE" >/dev/null
  fallback_ok || { echo "$PACKAGE isn't installed explicitly from $COPY after install" >&2; exit 1; }
}

case "${1:-install}" in
check)
  fetched || fallback_ok
  ;;
install)
  if fetched || fallback_ok; then
    exit 0
  fi
  if macos_volume; then
    from_macos
  else
    from_fallback
  fi
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
