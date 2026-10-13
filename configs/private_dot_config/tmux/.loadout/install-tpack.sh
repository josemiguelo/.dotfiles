#!/bin/sh
# tpack's latest GitHub release into ~/.local/bin, on Linux. The tpack cask
# depends on brew's tmux and git, which land ahead of the system's on PATH;
# Linux takes tmux from the system (Omarchy, dnf), so tpack comes from its
# release instead: a static binary, checked against the release's checksums.
# Run again, it installs the newest release over the old one.
set -eu

BIN_DIR="$HOME/.local/bin"
REPO="https://github.com/tmuxpack/tpack"

case "$(uname -m)" in
x86_64) ARCH=amd64 ;;
aarch64) ARCH=arm64 ;;
*)
  echo "unsupported architecture: $(uname -m)" >&2
  exit 1
  ;;
esac

# /releases/latest redirects to /releases/tag/v<version>.
VERSION=$(curl -fsSLo /dev/null -w '%{url_effective}' "$REPO/releases/latest")
VERSION=${VERSION##*/v}
[ -n "$VERSION" ] || { echo "no tpack release found" >&2; exit 1; }
FILE="tpack_${VERSION}_linux_${ARCH}.tar.gz"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/$FILE" "$REPO/releases/download/v$VERSION/$FILE"
curl -fsSL -o "$TMP/checksums.txt" "$REPO/releases/download/v$VERSION/checksums.txt"
(cd "$TMP" && grep "  $FILE\$" checksums.txt | sha256sum -c -)
tar -xzf "$TMP/$FILE" -C "$TMP" tpack

mkdir -p "$BIN_DIR"
# Renamed into place from the same folder, not copied over: a running tpack
# keeps its own file.
install -m 755 "$TMP/tpack" "$BIN_DIR/.tpack.new"
mv -f "$BIN_DIR/.tpack.new" "$BIN_DIR/tpack"
