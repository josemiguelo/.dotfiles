#!/bin/sh
# ngrok v3 binary into ~/.local/bin. equinox ships tgz for linux and zip
# for macOS (the source recipe hardcoded linux-amd64).
set -eu

BIN_DIR="$HOME/.local/bin"
BASE="https://bin.equinox.io/c/bNyj1mQVY4c"

case "$(uname -s)-$(uname -m)" in
Linux-x86_64) FILE="ngrok-v3-stable-linux-amd64.tgz" ;;
Linux-aarch64) FILE="ngrok-v3-stable-linux-arm64.tgz" ;;
Darwin-arm64) FILE="ngrok-v3-stable-darwin-arm64.zip" ;;
Darwin-x86_64) FILE="ngrok-v3-stable-darwin-amd64.zip" ;;
*)
  echo "unsupported platform: $(uname -s)/$(uname -m)" >&2
  exit 1
  ;;
esac

mkdir -p "$BIN_DIR"
# Downloaded whole first, failing on an HTTP error (-f): an error page never
# reaches tar or unzip. Equinox publishes no checksums for these files.
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/$FILE" "$BASE/$FILE"
case "$FILE" in
*.tgz) tar -xzf "$TMP/$FILE" -C "$BIN_DIR" ngrok ;;
*.zip) unzip -o "$TMP/$FILE" ngrok -d "$BIN_DIR" ;;
esac
chmod +x "$BIN_DIR/ngrok"
