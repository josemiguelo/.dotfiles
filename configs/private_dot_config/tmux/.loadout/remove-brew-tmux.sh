#!/bin/sh
# Linux: no tpack, tmux or git from brew. The tpack cask pulled in brew's tmux
# and git, which brew's bin put ahead of the system's on PATH: a tmux server of
# another version than the one Omarchy's own launches run, and another git.
# tpack now comes from its release (install-tpack.sh), so this removes the
# cask, then tmux and git unless another brew package still needs them (that
# one is reported and left alone: removing it would break the other).
# Modes: `check` / `install` (default).
set -eu

brew() { sh "$LOADOUT_REPO/configs/private_dot_config/.homebrew/.loadout/brew.sh" "$@"; }

# Without brew there's nothing to remove.
. "$LOADOUT_REPO/configs/private_dot_local/lib/brew-prefix.sh"
command -v brew >/dev/null 2>&1 || [ -x "$BREW_PREFIX/bin/brew" ] || exit 0

FORMULAE="tmux git"

# The formulae of FORMULAE brew has, with nothing installed needing them.
removable() {
  for f in $FORMULAE; do
    brew list --formula "$f" >/dev/null 2>&1 || continue
    [ -z "$(brew uses --installed "$f")" ] && echo "$f"
  done
  return 0
}

case "${1:-install}" in
check)
  status=0
  if brew list --cask tpack >/dev/null 2>&1; then
    echo "brew has the tpack cask"
    status=1
  fi
  for f in $(removable); do
    echo "brew has $f"
    status=1
  done
  exit $status
  ;;
install)
  if brew list --cask tpack >/dev/null 2>&1; then
    brew uninstall --cask tpack
  fi
  for f in $FORMULAE; do
    brew list --formula "$f" >/dev/null 2>&1 || continue
    users=$(brew uses --installed "$f")
    if [ -n "$users" ]; then
      echo "keeping brew's $f: needed by" $users >&2
    else
      brew uninstall --formula "$f"
    fi
  done
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
