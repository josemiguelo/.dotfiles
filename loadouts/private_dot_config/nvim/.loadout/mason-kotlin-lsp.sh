#!/bin/sh
# kotlin-lsp (kotlin.nvim's server), installed and kept current by Mason, with
# loadout watching it: its builds carry a licence that runs out a few weeks
# after their release, and the server then won't start, but Mason never
# updates what it has installed by itself. So Mason's newer version shows up
# in `loadout outdated`, and `loadout upgrade` has Mason install it (through
# outdated-kotlin-lsp.sh, the updates source). Neovim's
# kotlin.lua also asks Mason for it (ensure_installed). Mason is asked through
# mason.lua, under headless nvim, with mason.nvim from the lazy plugins
# (script.nvim-plugins clones it).
#
#   check      Mason has kotlin-lsp
#   install    Mason installs the latest (the default; an update when installed)
#   outdated   `kotlin-lsp <installed> <latest>` when Mason has a newer one
set -eu
PACKAGE=kotlin-lsp
# mise's shims, for the neovim the mise config pins, when this runs outside a
# shell that activated mise; brew's bin for macOS's coreutils `timeout`.
export PATH="$HOME/.local/bin:${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims:$PATH"
. "$LOADOUT_REPO/loadouts/private_dot_local/lib/brew-prefix.sh"
export PATH="$PATH:$BREW_PREFIX/bin"
CAP=$(command -v timeout || command -v gtimeout || true)
MASON_NVIM=${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/mason.nvim
LUA="$(cd "$(dirname "$0")" && pwd)/mason.lua"
# The global mise config only (nvim runs through its shim): from the repo's
# cwd mise would also find the dotfiles' copy in a parent.
cd "$HOME"

# Runs mason.lua in mode $1 (installs get 15 minutes, the download is ~500MB);
# prints its lines, or its reason and returns 1.
ask() {
  [ -d "$MASON_NVIM" ] || { echo "mason.nvim isn't cloned (script.nvim-plugins)"; return 1; }
  limit=120
  [ "$1" = install ] && limit=900
  out=$(mktemp)
  LOADOUT_MASON_OUT="$out" LOADOUT_MASON_MODE="$1" LOADOUT_MASON_PACKAGE="$PACKAGE" \
    ${CAP:+"$CAP" "$limit"} nvim --headless --clean \
    --cmd "set rtp^=$MASON_NVIM" -c "luafile $LUA" </dev/null >/dev/null 2>&1 || true
  if grep -qx '__LOADOUT_NVIM_OK__' "$out" 2>/dev/null; then
    grep -vx '__LOADOUT_NVIM_OK__' "$out" || true
    rm -f "$out"
    return 0
  fi
  reason=$(sed -n 's/^__LOADOUT_NVIM_ERR__ //p' "$out" 2>/dev/null)
  rm -f "$out"
  echo "${reason:-nvim did not answer}"
  return 1
}

# Mason's receipt is what makes a package installed; no nvim needed to see it.
installed() {
  [ -f "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/packages/$PACKAGE/mason-receipt.json" ]
}

install() {
  command -v nvim >/dev/null 2>&1 || { echo "nvim not found" >&2; exit 1; }
  result=$(ask install) || { echo "Mason couldn't install $PACKAGE: $result" >&2; exit 1; }
  installed || { echo "Mason reported $PACKAGE installed, but its receipt isn't there" >&2; exit 1; }
}

case "${1:-install}" in
check) installed ;;
install) install ;;
outdated)
  # Silent where there's nothing to report on; a visible row when Mason
  # couldn't answer, so a broken check never reads as up to date.
  command -v nvim >/dev/null 2>&1 && installed || exit 0
  line=$(ask versions) || { echo "$PACKAGE FAILED FAILED $line"; exit 0; }
  set -- $line
  [ "$1" = "$2" ] || echo "$PACKAGE $1 $2"
  ;;
*) echo "usage: $0 [check|install|outdated]" >&2; exit 2 ;;
esac
