#!/bin/sh
# Bar widgets drawing SVG icons instead of glyphs, with
# github.com/josemiguelo/omarchy-bar-icons: its bin/omarchy-bar-icons rebuilds
# each widget the opt-in names (one plugin id per word) from its source with
# the repo's patch, or installs the repo's own widgets, and checks them; see
# its README. The repo is the checkout in
# ~/Repos/gh/josemiguelo/omarchy-bar-icons, cloned when missing; install
# fast-forwards it first while it is clean and on master, and leaves local
# work alone otherwise. The repo is public: fetched over https, so a fresh
# machine clones it before GitHub knows its ssh key, and pushed over ssh
# (remote.origin.pushurl); an existing checkout gets both urls set too. When
# install fails, the plugins it rebuilds from a checkout that is behind its
# remote are named: the patches follow upstream, so one of those is the
# likely cause.
# usage: omarchy-bar-icons.sh [check] <id>...
set -eu

REPO=https://github.com/josemiguelo/omarchy-bar-icons.git
PUSH_URL=git@github.com:josemiguelo/omarchy-bar-icons.git
CHECKOUT=$HOME/Repos/gh/josemiguelo/omarchy-bar-icons
TOOL=$CHECKOUT/bin/omarchy-bar-icons
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/shell-ready.sh"
. "$HERE/lib/plugin-update-hint.sh"
shell_ready

remotes_ok() {
  [ "$(git -C "$CHECKOUT" config --get remote.origin.url)" = "$REPO" ] &&
    [ "$(git -C "$CHECKOUT" config --get remote.origin.pushurl)" = "$PUSH_URL" ]
}

if [ "${1:-}" = check ]; then
  [ -x "$TOOL" ] && remotes_ok || exit 1
  exec "$TOOL" "$@"
fi

if [ ! -d "$CHECKOUT/.git" ]; then
  mkdir -p "$(dirname "$CHECKOUT")"
  git clone --quiet "$REPO" "$CHECKOUT"
fi
if ! remotes_ok; then
  git -C "$CHECKOUT" config remote.origin.url "$REPO"
  git -C "$CHECKOUT" config remote.origin.pushurl "$PUSH_URL"
fi
if [ "$(git -C "$CHECKOUT" branch --show-current)" = master ] && [ -z "$(git -C "$CHECKOUT" status --porcelain)" ]; then
  git -C "$CHECKOUT" pull --quiet --ff-only ||
    echo "couldn't fast-forward $CHECKOUT; using it as it is" >&2
fi
"$TOOL" "$@" || { status=$?; plugin_update_hint "$@"; exit "$status"; }
