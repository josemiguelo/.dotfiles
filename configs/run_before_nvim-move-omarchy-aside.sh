#!/bin/sh
# Omarchy ships its own LazyVim config in ~/.config/nvim (copied from
# /etc/skel). chezmoi only replaces the files it manages, so Omarchy's other
# files would stay and load under ours (plugin/after/transparency.lua makes
# every background see-through). Before the first apply on a fresh Omarchy,
# when ~/.config/nvim is still that copy (its init.lua byte for byte), move it
# aside whole, as ~/.config/nvim.pre-chezmoi. Once ours is applied init.lua is
# ours, so every later apply (and every non-Omarchy machine) does nothing.
set -eu

SKEL=/etc/skel/.config/nvim
NVIM=${XDG_CONFIG_HOME:-$HOME/.config}/nvim

[ -f "$SKEL/init.lua" ] && [ -f "$NVIM/init.lua" ] || exit 0
cmp -s "$SKEL/init.lua" "$NVIM/init.lua" || exit 0

aside=$NVIM.pre-chezmoi
[ ! -e "$aside" ] || aside=$aside.$(date +%Y%m%d%H%M%S)
mv "$NVIM" "$aside"
echo "moved Omarchy's Neovim config aside: $aside"
