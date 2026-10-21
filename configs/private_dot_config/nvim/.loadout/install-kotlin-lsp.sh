#!/bin/sh
# kotlin-lsp's latest release (github.com/Kotlin/kotlin-lsp) into
# ~/.local/share/kotlin-lsp/<version>, with `current` linked to it; Neovim's
# kotlin.lua points kotlin.nvim there (KOTLIN_LSP_DIR). Mason would install
# it, but its registry downloads from download-cdn.jetbrains.com, which
# answers 404 for every build (mason-registry#17523, fix in #17323); once
# that merges, this goes and Mason installs it again.
#
# A build carries a licence that runs out a few weeks after its release, and
# the server then won't start (`:checkhealth kotlin` shows the date), so
# loadout's update check (outdated-kotlin-lsp.sh) matters here. The archive
# bundles its own Java runtime and is checked against the release's
# SHA-256. Run again, it installs the newest release beside the old one,
# moves `current` and removes the others (a server already running keeps
# working until it restarts).
set -eu

ROOT=$HOME/.local/share/kotlin-lsp
REPO=https://github.com/Kotlin/kotlin-lsp
DOWNLOADS=https://download.jetbrains.com/language-server/kotlin-server

case "$(uname -s)-$(uname -m)" in
Linux-x86_64) SUFFIX=.tar.gz ;;
Linux-aarch64) SUFFIX=-aarch64.tar.gz ;;
Darwin-x86_64) SUFFIX=.sit ;;
Darwin-arm64) SUFFIX=-aarch64.sit ;;
*)
  echo "unsupported platform: $(uname -s) $(uname -m)" >&2
  exit 1
  ;;
esac

# /releases/latest redirects to /releases/tag/kotlin-lsp/v<version>.
VERSION=$(curl -fsSLo /dev/null -w '%{url_effective}' "$REPO/releases/latest")
VERSION=${VERSION##*/v}
case "$VERSION" in '' | *[!0-9.]*) echo "no kotlin-lsp release found" >&2; exit 1 ;; esac
FILE=kotlin-server-$VERSION$SUFFIX

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/$FILE" "$DOWNLOADS/$VERSION/$FILE"
# The checksum file reads `<hash> *<file>`; macOS has shasum, not sha256sum.
want=$(curl -fsSL "$DOWNLOADS/$VERSION/$FILE.sha256" | cut -d' ' -f1)
if command -v sha256sum >/dev/null; then
  got=$(sha256sum "$TMP/$FILE" | cut -d' ' -f1)
else
  got=$(shasum -a 256 "$TMP/$FILE" | cut -d' ' -f1)
fi
[ -n "$want" ] && [ "$got" = "$want" ] || { echo "$FILE doesn't match its SHA-256" >&2; exit 1; }

# Everything sits under kotlin-server-<version>/ in the archive.
mkdir -p "$TMP/out" "$ROOT"
case "$FILE" in
*.tar.gz) tar -xzf "$TMP/$FILE" -C "$TMP/out" --strip-components=1 ;;
*.sit) unzip -q "$TMP/$FILE" -d "$TMP/unzipped" && mv "$TMP/unzipped"/*/* "$TMP/out" ;;
esac
[ -x "$TMP/out/bin/intellij-server" ] || { echo "$FILE has no bin/intellij-server" >&2; exit 1; }

rm -rf "$ROOT/$VERSION"
mv "$TMP/out" "$ROOT/$VERSION"
ln -sfn "$VERSION" "$ROOT/current"
for dir in "$ROOT"/*/; do
  [ "$(basename "$dir")" = "$VERSION" ] || [ -L "${dir%/}" ] || rm -rf "$dir"
done
echo "kotlin-lsp $VERSION"
