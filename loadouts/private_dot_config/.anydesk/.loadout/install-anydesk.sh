#!/bin/sh
# AnyDesk from a pinned direct rpm (no repo — bump the URL to upgrade).
set -eu

RPM=$(mktemp --suffix=.rpm)
trap 'rm -f "$RPM"' EXIT
curl -1sLf -o "$RPM" https://download.anydesk.com/linux/anydesk_8.0.3-1_x86_64.rpm
sudo dnf install -y "$RPM"
