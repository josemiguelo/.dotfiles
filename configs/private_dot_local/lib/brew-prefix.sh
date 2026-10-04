# Homebrew's prefix on this OS, the one place that decides it. Sourced, not
# run (sh, bash and zsh all read it), by everything that needs brew without a
# shell that has run `brew shellenv`: loadout's scripts from the repo, as
# "$LOADOUT_REPO/configs/private_dot_local/lib/brew-prefix.sh" (on a fresh
# machine they run before the dotfiles are applied), everything else from
# ~/.local/lib/brew-prefix.sh. It only sets BREW_PREFIX, by OS rather than by
# what exists, so setup-brew can install there: check for $BREW_PREFIX/bin/brew
# before relying on it. $OSTYPE spares zsh and bash a fork; sh has no $OSTYPE.
case "${OSTYPE:-$(uname -s)}" in
darwin* | Darwin) BREW_PREFIX=/opt/homebrew ;;
*) BREW_PREFIX=/home/linuxbrew/.linuxbrew ;;
esac
