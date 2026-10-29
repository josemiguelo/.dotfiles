#!/bin/sh
# brew by absolute path, so converging never depends on the shell having run
# `brew shellenv` (on a fresh machine the dotfiles that do that come AFTER the
# programs). A PATH brew is honoured first so a custom prefix still works, then
# this OS's prefix (brew-prefix.sh). Every brew command the repo runs itself
# goes through here: the brew-tap installers as `file:.loadout/brew.sh`,
# anything else as `sh "$LOADOUT_REPO/loadouts/private_dot_config/.homebrew/.loadout/brew.sh" <brew args...>`.
# loadout's own brew installers find brew through setup-brew's `provides`.
set -eu
. "$LOADOUT_REPO/loadouts/private_dot_local/lib/brew-prefix.sh"
# Homebrew asks before an install that pulls in dependencies; a converge must
# run unattended.
export HOMEBREW_NO_ASK=1

for b in "$(command -v brew 2>/dev/null || true)" "$BREW_PREFIX/bin/brew"; do
  if [ -n "$b" ] && [ -x "$b" ]; then
    exec "$b" "$@"
  fi
done

echo "brew is not installed (setup-brew installs it on Linux)" >&2
exit 1
