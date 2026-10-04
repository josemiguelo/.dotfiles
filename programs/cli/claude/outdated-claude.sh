#!/bin/sh
# claude's own outdated check (programs/cli/claude/claude.yaml): is the claude
# binary behind the latest published Claude Code release? claude.ai/install.sh
# installs it as a plain self-updating binary, so no package manager knows
# about it. `claude update` does the upgrade in place, so no re-install needed.
#
#   outdated-claude.sh          print the latest version when behind, else nothing
#   outdated-claude.sh update   install the latest release over the current binary
#
# Silent when claude isn't installed or the network is down — and when the
# claude here isn't the native install: on Omarchy mise owns it (the dotfiles'
# mise config, updated by `omarchy update`), and ~/.local/bin/claude is
# Omarchy's wrapper script, not the binary, so `claude update` would fight
# mise. The native installer's layout is the tell: ~/.local/bin/claude is a
# symlink into ~/.local/share/claude/.
set -eu

NATIVE="$HOME/.local/bin/claude"

current() {
  case "$(readlink "$NATIVE" 2>/dev/null)" in
    "$HOME/.local/share/claude/"*) ;;
    *) return 0 ;;
  esac
  "$NATIVE" --version 2>/dev/null | sed -n 's/^\([0-9][0-9.]*\).*/\1/p'
}

latest() {
  curl -fsSL https://downloads.claude.ai/claude-code-releases/latest 2>/dev/null
}

case ${1:-} in
update)
  "$NATIVE" update
  echo "claude $(current)"
  ;;
"")
  cur=$(current) || exit 0
  [ -n "$cur" ] || exit 0
  new=$(latest) || exit 0
  [ -n "$new" ] && [ "$new" != "$cur" ] && echo "$new"
  exit 0
  ;;
*)
  echo "usage: $0 [update]" >&2
  exit 2
  ;;
esac
