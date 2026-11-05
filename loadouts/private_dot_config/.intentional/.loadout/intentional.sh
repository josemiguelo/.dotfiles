#!/bin/sh
# Intentional's desktop guard from its latest GitHub release
# (github.com/josemiguelo/intentional): the archive is checked against its
# SHA-256 and its own install.sh installs it (binary, systemd user unit,
# Brave extension, native-messaging manifest, the brave-flags.conf line),
# keeping a copy of itself in ~/.local/share/intentional for `check`, which
# prints the installed version. Modes: `check` / `install` (default).
set -eu

REPO=https://github.com/josemiguelo/intentional
installed="${XDG_DATA_HOME:-$HOME/.local/share}/intentional/install.sh"

case "${1:-install}" in
check)
  [ -x "$installed" ] || exit 1
  exec sh "$installed" check
  ;;
install) ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac

case "$(uname -s)-$(uname -m)" in
Linux-x86_64) ;;
*) echo "no Intentional build for $(uname -s) $(uname -m)" >&2; exit 1 ;;
esac

# /releases/latest redirects to /releases/tag/v<version>.
VERSION=$(curl -fsSLo /dev/null -w '%{url_effective}' "$REPO/releases/latest")
VERSION=${VERSION##*/v}
case "$VERSION" in '' | *[!0-9.]*) echo "no Intentional release found" >&2; exit 1 ;; esac
FILE=intentional-$VERSION-linux-x64.tar.gz

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/$FILE" "$REPO/releases/download/v$VERSION/$FILE"
want=$(curl -fsSL "$REPO/releases/download/v$VERSION/$FILE.sha256" | cut -d' ' -f1)
got=$(sha256sum "$TMP/$FILE" | cut -d' ' -f1)
[ -n "$want" ] && [ "$got" = "$want" ] || { echo "$FILE doesn't match its SHA-256" >&2; exit 1; }

tar -xzf "$TMP/$FILE" -C "$TMP"
sh "$TMP/intentional-$VERSION/install.sh" install
