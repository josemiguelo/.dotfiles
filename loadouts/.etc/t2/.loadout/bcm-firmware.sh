#!/bin/sh
# The T2 Wi-Fi/Bluetooth firmware, apple-bcm-firmware 14.0-1, kept installed
# (docs/t2-macbook.md). The package has left the repos, Omarchy's installer
# puts apple-bcm-firmware-fetcher in its place (which needs a macOS volume
# this Mac doesn't have, and conflicts with it), and from Omarchy 4.5
# `omarchy-update` removes orphans on its own. Apple's firmware can't go into
# this public repo, so the package is a document in 1Password (Personal
# vault, titled by its file name), and a copy verified against SHA256 below
# is kept at $COPY, outside the pacman cache that paccache trims.
#
# install, each step only when needed:
# - the local copy: from the pacman cache when it still has the package,
#   else from 1Password (which needs a network: on a fresh install, before
#   this firmware is back, USB tethering or a USB Ethernet adapter);
# - the package installed from that copy with `pacman -U`, after removing
#   apple-bcm-firmware-fetcher, which conflicts with it; the Wi-Fi driver
#   reloads to pick the firmware up;
# - the package marked explicitly installed, so no orphan cleanup takes it.
# check: the package installed with all its files, explicitly, and the copy
# in place. It never asks 1Password anything.
# Modes: `check` / `install` (default).
set -eu

PACKAGE=apple-bcm-firmware
FILE=apple-bcm-firmware-14.0-1-any.pkg.tar.zst
SHA256=f2cd47d9e3fb9658f16997b2d9ace3033b57925b8c6ddd86ccc3d07d0c3e9559
CACHE=/var/cache/pacman/pkg/$FILE
COPY=/var/lib/t2-bcm-firmware/$FILE
VAULT=Personal

verified() {
  [ -f "$1" ] && [ "$(sha256sum "$1" | cut -d' ' -f1)" = "$SHA256" ]
}

installed() {
  pacman -Qk "$PACKAGE" >/dev/null 2>&1
}

explicit() {
  pacman -Qqe "$PACKAGE" >/dev/null 2>&1
}

case "${1:-install}" in
check)
  installed && explicit && verified "$COPY"
  ;;
install)
  if ! verified "$COPY"; then
    if verified "$CACHE"; then
      source=$CACHE
    else
      op vault list >/dev/null 2>&1 || {
        echo "no copy of $FILE here, and 1Password isn't unlocked for the CLI: unlock the app (and approve its prompt), then run this again" >&2
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
  if ! installed; then
    if pacman -Q apple-bcm-firmware-fetcher >/dev/null 2>&1; then
      sudo pacman -R --noconfirm apple-bcm-firmware-fetcher
    fi
    sudo pacman -U --noconfirm "$COPY"
    # brcmfmac read no firmware when it loaded; loading it again reads it now.
    sudo modprobe -r brcmfmac 2>/dev/null && sudo modprobe brcmfmac 2>/dev/null ||
      echo "reboot for the Wi-Fi to pick up the firmware" >&2
  fi
  explicit || sudo pacman -D --asexplicit "$PACKAGE" >/dev/null
  installed && explicit && verified "$COPY" ||
    { echo "$PACKAGE isn't installed explicitly from $COPY after install" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
