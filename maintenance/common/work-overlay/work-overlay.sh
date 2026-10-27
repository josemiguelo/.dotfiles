#!/bin/sh
# The work machine's overlay: what only it has and this public repo mustn't
# say (its employer's tooling, the private repos it works in), kept in a
# private repo of josemiguelo's. Cloned as bare-repos clones (over ssh: https
# can't fetch a private repo without credentials), then its own install.sh
# puts its files where this repo's hooks look for them (zsh's conf.d,
# Neovim's lua/overlay, the palette's commands.local, the session extras);
# check asks that install.sh too. Without the overlay every hook is a no-op.
# usage: work-overlay.sh [check] <repo>
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
REPO=${1:?usage: $0 [check] <repo>}
DIR=$HOME/Repos/gh/josemiguelo/$REPO
BARE="$LOADOUT_REPO/maintenance/common/repos/bare-repos.sh"

if [ "$MODE" = check ]; then
  sh "$BARE" check --ssh "$REPO" >/dev/null || exit 1
else
  sh "$BARE" --ssh "$REPO"
fi
branch=$(git -C "$DIR" symbolic-ref --quiet --short HEAD)
INSTALL=$DIR/all_worktrees/$branch/install.sh
[ -f "$INSTALL" ] || { echo "work-overlay: $REPO has no install.sh" >&2; exit 1; }
if [ "$MODE" = check ]; then
  sh "$INSTALL" check
else
  sh "$INSTALL"
fi
