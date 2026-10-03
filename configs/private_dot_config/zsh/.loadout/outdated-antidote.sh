#!/bin/sh
# Custom `loadout outdated` oracle: is antidote itself behind its GitHub tip?
# Its bundles are a separate oracle (antidote-plugins). Silent when antidote
# isn't cloned on this machine.
set -eu
# Same expression the installer clones into (plugins.sh, beside this file):
# with XDG_DATA_HOME set, a hardcoded ~/.local/share looked where antidote
# was never installed, and this oracle goes silent rather than saying so.
GCB_NAME='echo antidote' \
  exec sh "$LOADOUT_REPO/maintenance/lib/git-clones-behind.sh" "$@" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/mattmc3/antidote"
