#!/bin/sh
# A new machine, from nothing to its whole loadout, in one command:
#
#   curl -fsSL https://raw.githubusercontent.com/josemiguelo/.dotfiles/master/bootstrap.sh | sh -s -- <machine>
#
# <machine> names machines/<machine>.yaml in this repo and becomes the
# hostname, so loadout, chezmoi's templates and the state file all agree on
# it. The order is the point: the hostname before the first apply (templates
# rendered for an unknown host get the defaults, e.g. omarchy: false), the
# dotfiles before setup-new-machine (its scripts read the applied configs).
#
#   1. machines/<machine>.yaml exists (asked over https, before any change)
#   2. git and chezmoi
#   3. the hostname
#   4. ~/.local given back to the user where a root-run installer took it
#   5. chezmoi init --apply over https (the repo is public; github-ssh-key
#      registers this machine's key later, and pushes go over ssh)
#   6. loadout
#   7. loadout setup-new-machine --yes, MISE_IGNORED_CONFIG_PATHS set as zsh
#      would (from the repo's dirs mise would otherwise ask to trust its copy
#      of mise's config)
#
# Safe to run again: every step skips what's done. --dry-run prints the
# commands without running them.
# usage: bootstrap.sh [--dry-run] <machine>
set -eu

GH=josemiguelo/.dotfiles
RAW=https://raw.githubusercontent.com/$GH/master
REPO=$HOME/.local/share/chezmoi
LOADOUT_INSTALL=https://raw.githubusercontent.com/josemiguelo/loadout/master/install.sh

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { printf 'bootstrap: %s\n' "$*" >&2; exit 1; }
run() {
  printf '  + %s\n' "$*"
  [ -n "$DRY" ] || "$@"
}

main() {
  DRY=
  if [ "${1:-}" = --dry-run ]; then DRY=1; shift; fi
  MACHINE=${1:-}
  [ -n "$MACHINE" ] || die "usage: bootstrap.sh [--dry-run] <machine>  (a file in https://github.com/$GH/tree/master/machines)"
  OS=$(uname -s)
  OMARCHY=
  command -v omarchy >/dev/null 2>&1 && OMARCHY=1

  say "1. machines/$MACHINE.yaml"
  if ! curl -fsL -o /dev/null "$RAW/machines/$MACHINE.yaml"; then
    cat >&2 <<EOF
bootstrap: no machines/$MACHINE.yaml in $GH.
A machine new to the repo gets a file first, extending its profiles, e.g.
  # MacBookPro16,1 (T2) running Omarchy.
  extends: [t2-macbook]
(profiles/: $(curl -fsSL "https://api.github.com/repos/$GH/contents/profiles" 2>/dev/null |
      sed -n 's/.*"name": "\(.*\)\.yaml".*/\1/p' | tr '\n' ' '))
Commit and push it, then run this again.
EOF
    exit 1
  fi

  say "2. git and chezmoi"
  command -v git >/dev/null 2>&1 && { command -v chezmoi >/dev/null 2>&1 || [ -x "$HOME/.local/bin/chezmoi" ]; } &&
    echo "  present"
  if ! command -v git >/dev/null 2>&1; then
    if [ -n "$OMARCHY" ]; then run omarchy pkg add git
    elif [ "$OS" = Darwin ]; then run xcode-select --install; die "install the command line tools, then run this again"
    elif command -v dnf >/dev/null 2>&1; then run sudo dnf install -y git
    else die "install git, then run this again"
    fi
  fi
  if ! command -v chezmoi >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/chezmoi" ]; then
    if [ -n "$OMARCHY" ]; then run omarchy pkg add chezmoi
    else run sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
    fi
  fi
  PATH=$HOME/.local/bin:$PATH

  say "3. hostname"
  current=$(hostname -s 2>/dev/null || hostname)
  if [ "$current" != "$MACHINE" ]; then
    if [ "$OS" = Darwin ]; then
      for name in HostName LocalHostName ComputerName; do run sudo scutil --set "$name" "$MACHINE"; done
    else
      run sudo hostnamectl set-hostname "$MACHINE"
    fi
  else
    echo "  already $MACHINE"
  fi

  say "4. ~/.local ownership"
  if [ -d "$HOME/.local" ] && [ -n "$(find "$HOME/.local" ! -user "$(id -u)" -print -quit 2>/dev/null)" ]; then
    run sh -c 'find "$HOME/.local" ! -user "$(id -u)" -exec sudo chown "$(id -u):$(id -g)" {} +'
  else
    echo "  all yours"
  fi

  say "5. dotfiles"
  run chezmoi init --apply "https://github.com/$GH.git"

  say "6. loadout"
  if [ ! -x "$HOME/.local/bin/loadout" ] && ! command -v loadout >/dev/null 2>&1; then
    run sh -c "curl -fsSL $LOADOUT_INSTALL | sh"
  else
    echo "  installed"
  fi

  say "7. loadout setup-new-machine"
  run env LOADOUT_REPO="$REPO" \
    MISE_IGNORED_CONFIG_PATHS="$REPO:$HOME/.local/share/chezmoi__worktrees" \
    loadout --repo "$REPO" --machine "$MACHINE" setup-new-machine --yes

  say "done: $MACHINE"
  echo "Reboot now: the login shell, new groups (docker, libvirt), the rebuilt"
  echo "initramfs and the session's environment only apply after it."
}

# Last, with the terminal as input: under `curl | sh` the script itself is
# stdin, and sudo, gh's login and the installers need a terminal to ask on.
if [ -t 0 ]; then main "$@"; else main "$@" </dev/tty; fi
