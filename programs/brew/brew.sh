#!/bin/sh
# brew by absolute path, so converging never depends on the shell having run
# `brew shellenv` (on a fresh machine the dotfiles that do that come AFTER the
# programs). A PATH brew is honoured first so a custom prefix still works, then
# this OS's prefix (brew-prefix.sh). Every brew/brew-cask command in the repo
# runs through here: the installers beside it as `file:brew.sh`, anything
# else as `sh "$LOADOUT_REPO/programs/brew/brew.sh" <brew args...>`.
set -eu
. "$LOADOUT_REPO/configs/private_dot_local/lib/brew-prefix.sh"

for b in "$(command -v brew 2>/dev/null || true)" "$BREW_PREFIX/bin/brew"; do
  if [ -n "$b" ] && [ -x "$b" ]; then
    exec "$b" "$@"
  fi
done

echo "brew is not installed (setup-brew installs it on Linux)" >&2
exit 1
