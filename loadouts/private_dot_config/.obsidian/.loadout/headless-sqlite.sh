#!/bin/sh
# omalauncher: obsidian-headless (`ob`, from mise's npm backend) needs
# better-sqlite3's native binding, which its install script fetches with
# prebuild-install. There that request times out, though curl and node
# themselves reach GitHub fine, and the fallback, node-gyp, has no compiler to
# build with; `ob sync` then fails with "Could not locate the bindings file".
# This fetches the same prebuilt binding with curl, for each installed
# obsidian-headless, matching its better-sqlite3 version and node's ABI.
# Modes: `check` / `install` (default).
set -eu

INSTALLS="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/installs/npm-obsidian-headless"
command -v mise >/dev/null 2>&1 || { echo "mise not found" >&2; exit 1; }
cd "$HOME"

# better-sqlite3's folder in every installed obsidian-headless; mise's
# aliases (latest, 0.0, ...) are links to those.
modules() {
  for v in "$INSTALLS"/*; do
    d="$v/lib/node_modules/obsidian-headless/node_modules/better-sqlite3"
    [ ! -L "$v" ] && [ -f "$d/package.json" ] && echo "$d"
  done
}

missing=0
for d in $(modules); do
  [ -f "$d/build/Release/better_sqlite3.node" ] && continue
  missing=1
  [ "${1:-install}" = check ] && break
  version=$(mise exec node -- node -p "require('$d/package.json').version")
  abi=$(mise exec node -- node -p process.versions.modules)
  echo "better-sqlite3 $version for node ABI $abi into $d"
  curl -fsSL "https://github.com/WiseLibs/better-sqlite3/releases/download/v$version/better-sqlite3-v$version-node-v$abi-linux-arm64.tar.gz" |
    tar -xz -C "$d"
done

case "${1:-install}" in
  check) exit "$missing" ;;
  install) ;;
  *) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
