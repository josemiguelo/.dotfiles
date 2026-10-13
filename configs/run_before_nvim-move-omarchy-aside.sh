#!/bin/sh
# Omarchy ships its own LazyVim config in ~/.config/nvim (copied from
# /etc/skel). chezmoi only replaces the files it manages, so Omarchy's other
# files would stay and load under ours (plugin/after/transparency.lua makes
# every background see-through). Before the first apply on a fresh Omarchy,
# when ~/.config/nvim is still that copy (its init.lua byte for byte), move it
# aside whole, as ~/.config/nvim.pre-chezmoi. Once ours is applied init.lua is
# ours, so every later apply (and every non-Omarchy machine) does nothing.
#
# Its plugins go aside with it: Omarchy also ships them, as shallow clones in
# ~/.local/share/nvim (from /etc/skel too). Left there, `Lazy! restore`
# (scripts.nvim-plugins) can't reach our locked commits in a clone without
# history, keeps Omarchy's, and rewrites our lazy-lock.json to match.
set -eu

SKEL=/etc/skel/.config/nvim
NVIM=${XDG_CONFIG_HOME:-$HOME/.config}/nvim
DATA=${XDG_DATA_HOME:-$HOME/.local/share}/nvim

[ -f "$SKEL/init.lua" ] && [ -f "$NVIM/init.lua" ] || exit 0
cmp -s "$SKEL/init.lua" "$NVIM/init.lua" || exit 0

move_aside() {
  aside=$1.pre-chezmoi
  [ ! -e "$aside" ] || aside=$aside.$(date +%Y%m%d%H%M%S)
  mv "$1" "$aside"
  echo "moved Omarchy's $2 aside: $aside"
}
move_aside "$NVIM" "Neovim config"
[ ! -d "$DATA" ] || move_aside "$DATA" "Neovim plugins"
