#!/bin/sh
# Global git identity + delta/merge config. Name and email are the same on
# every machine, the email GitHub's noreply address: this repo is public, and
# commits carry it. What one machine needs on top, a work email for its work
# repos say, goes in ~/.gitconfig.local, which this file includes last (so it
# wins) and which never enters the repo; git skips the include while it
# doesn't exist. E.g. on the work machine:
#   [includeIf "gitdir:~/Work/"]
#       path = ~/.gitconfig-work   # [user] email = <work address>
#
# Written to ~/.gitconfig by name, never with `--global`: that writes to
# ~/.config/git/config whenever ~/.gitconfig doesn't exist yet — on Omarchy
# that's Omarchy's own file, which `omarchy-reinstall-configs` puts back to
# its defaults. git reads both, and ~/.gitconfig wins a key they share.
#
# Read by name too: once ~/.gitconfig exists, `git config --global` reads
# ONLY that file, so Omarchy's identity in ~/.config/git/config would look
# unset and get overwritten.
# Modes: `check` / `install` (default).
set -eu

DESIRED_EMAIL="15330034+josemiguelo@users.noreply.github.com"
DESIRED_NAME="Jose Miguel Ochoa"
GITCONFIG="$HOME/.gitconfig"
LOCAL='~/.gitconfig.local'
XDG_GITCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"

# A key's global value as git itself resolves it: ~/.gitconfig first.
global_get() {
  git config --file "$GITCONFIG" --get "$1" 2>/dev/null ||
    git config --file "$XDG_GITCONFIG" --get "$1" 2>/dev/null ||
    true
}

case "${1:-install}" in
check)
  [ "$(global_get user.email)" = "$DESIRED_EMAIL" ] &&
    [ "$(global_get user.name)" = "$DESIRED_NAME" ] &&
    [ "$(global_get core.pager)" = delta ] &&
    [ "$(global_get merge.conflictStyle)" = zdiff3 ] &&
    git config --file "$GITCONFIG" --get-all include.path 2>/dev/null | grep -qxF "$LOCAL"
  ;;
install)
  # In ~/.gitconfig even when Omarchy's installer set others: these win.
  git config --file "$GITCONFIG" user.email "$DESIRED_EMAIL"
  git config --file "$GITCONFIG" user.name "$DESIRED_NAME"
  git config --file "$GITCONFIG" core.pager delta
  git config --file "$GITCONFIG" interactive.diffFilter 'delta --color-only'
  git config --file "$GITCONFIG" delta.navigate true
  git config --file "$GITCONFIG" merge.conflictStyle zdiff3
  # Added after the identity, so it lands below it: an include's values win
  # only over what comes before it.
  git config --file "$GITCONFIG" --get-all include.path 2>/dev/null | grep -qxF "$LOCAL" ||
    git config --file "$GITCONFIG" --add include.path "$LOCAL"
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
