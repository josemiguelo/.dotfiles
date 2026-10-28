#!/bin/sh
# sudo from Arch's repos, installed by root: there's no sudo to run pacman with yet.
set -eu

[ "$(id -u)" = 0 ] || { echo "install-sudo.sh installs sudo as root; this is $(id -un)" >&2; exit 1; }
pacman -S --noconfirm --needed sudo
