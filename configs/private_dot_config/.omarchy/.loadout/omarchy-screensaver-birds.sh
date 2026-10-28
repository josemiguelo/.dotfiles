#!/bin/sh
# Omarchy's screensaver as a flock of birds (github.com/clainstone/cbirds)
# instead of a random TTE effect from ttfx. The screensaver itself is
# ./omarchy-screensaver (what it draws, and how, is described there); this
# builds cbirds and puts that file in Omarchy's command's place.
#
# cbirds holds a picture 30 to 45 seconds before letting go, which on a
# screensaver reads as frozen, and has no option for it. So cbirds is built
# from its checkout in ~/Repos/gh/clainstone/cbirds (cloned over https when
# missing), from a local branch, omarchy-hold: its release tag with
# cbirds-hold.patch committed on top, which adds `--hold SECONDS`. The build
# takes the branch's tree (git archive), not the working copy, so whatever is
# checked out there, local work included, doesn't reach the binary; it goes
# into ~/.local/bin, and its version says `+hold`. The check reads that, the
# remote, and whether the branch carries exactly the patch (compared by `git
# patch-id`); a branch that doesn't is left alone and install stops, since
# it may hold work. Goes back to the brew tap (clainstone/tap) if upstream
# takes the option.
#
# omarchy-launch-screensaver runs `omarchy-screensaver` in a terminal it
# starts from Hyprland, so a copy of ./omarchy-screensaver in the directory
# omarchy-command-overrides puts first on that PATH takes its place. The
# launcher itself is Omarchy's and still requires ttfx to be installed. The
# check requires the session to actually run the replacement.
# Modes: `check` / `install` (default).
set -eu

COMMAND=omarchy-screensaver
HERE="$(cd "$(dirname "$0")" && pwd)"
PROBE=$HERE/../../../../lib/omarchy/hypr-option.lua
. "$HERE/../../../../lib/omarchy/omarchy-overrides-lib.sh"
SOURCE=$HERE/$COMMAND
WRAPPER=$OVERRIDES_DIR/$COMMAND
REPO=https://github.com/clainstone/cbirds.git
CHECKOUT=$HOME/Repos/gh/clainstone/cbirds
TAG=v1.7.0
TAG_COMMIT=dc22807b132c9a8ca819413faacf25973ecb376a
BRANCH=omarchy-hold
PATCH=$HERE/cbirds-hold.patch
# The screensaver runs this path; keep the two in step.
BIN=$HOME/.local/bin/cbirds
BUILT="cbirds ${TAG#v}+hold"

die() {
  echo "$@" >&2
  exit 1
}

built() {
  [ -x "$BIN" ] && [ "$("$BIN" --version 2>/dev/null)" = "$BUILT" ]
}

cloned() {
  [ -d "$CHECKOUT/.git" ] && [ "$(git -C "$CHECKOUT" config --get remote.origin.url)" = "$REPO" ]
}

# The branch is the tag and the patch, nothing more.
patched() {
  [ "$(git -C "$CHECKOUT" rev-parse --verify --quiet "$BRANCH~1^{commit}")" = "$TAG_COMMIT" ] &&
    [ "$(git -C "$CHECKOUT" diff "$TAG_COMMIT" "$BRANCH" | git patch-id --stable | cut -d' ' -f1)" = \
      "$(git patch-id --stable < "$PATCH" | cut -d' ' -f1)" ]
}

branch_exists() {
  git -C "$CHECKOUT" rev-parse --verify --quiet "refs/heads/$BRANCH" >/dev/null
}

installed() {
  [ -x "$WRAPPER" ] && cmp -s "$SOURCE" "$WRAPPER" && override_active "$COMMAND"
}

# The checkout, pointing at $REPO, with $TAG fetched and still $TAG_COMMIT.
clone() {
  if [ ! -d "$CHECKOUT/.git" ]; then
    mkdir -p "$(dirname "$CHECKOUT")"
    git clone --quiet "$REPO" "$CHECKOUT"
  fi
  cloned || git -C "$CHECKOUT" config remote.origin.url "$REPO"
  git -C "$CHECKOUT" rev-parse --verify --quiet "$TAG_COMMIT^{commit}" >/dev/null ||
    git -C "$CHECKOUT" fetch --quiet origin tag "$TAG"
  [ "$(git -C "$CHECKOUT" rev-parse "$TAG^{commit}")" = "$TAG_COMMIT" ] ||
    die "$REPO $TAG isn't $TAG_COMMIT any more"
}

# $BRANCH: the tag with the patch committed on top. In a worktree of its own,
# so the patch is committed without touching the checkout's working copy.
create_branch() {
  tmp=$(mktemp -d)
  trap 'git -C "$CHECKOUT" worktree remove --force "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
  git -C "$CHECKOUT" worktree add --quiet -b "$BRANCH" "$tmp" "$TAG_COMMIT"
  git -C "$tmp" apply --index "$PATCH"
  git -C "$tmp" commit --quiet -m "Add --hold SECONDS: how long a sign is held

Managed by loadout (omarchy-screensaver-birds), from cbirds-hold.patch."
  git -C "$CHECKOUT" worktree remove "$tmp"
  trap - EXIT
}

# cbirds from the branch's tree into ~/.local/bin.
build() {
  src=$(mktemp -d)
  trap 'rm -rf "$src"' EXIT
  git -C "$CHECKOUT" archive "$BRANCH" | tar -x -C "$src"
  make -s -C "$src" install PREFIX="$HOME/.local"
  rm -rf "$src"
  trap - EXIT
  built || die "$BIN doesn't say $BUILT after the build"
}

install_wrapper() {
  mkdir -p "$OVERRIDES_DIR"
  cp "$SOURCE" "$WRAPPER"
  chmod 755 "$WRAPPER"
  installed || die "the session doesn't run $WRAPPER: is omarchy-command-overrides installed?"
}

case "${1:-install}" in
check)
  cloned && patched && built && installed
  ;;
install)
  clone
  branch_exists || create_branch
  patched || die "$CHECKOUT's $BRANCH isn't $TAG with cbirds-hold.patch: move it aside (git branch -m $BRANCH …) and install again"
  built || build
  install_wrapper
  echo "Try it: omarchy-launch-screensaver force"
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
