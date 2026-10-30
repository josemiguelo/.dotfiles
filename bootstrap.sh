#!/bin/sh
# A new machine, from nothing to its whole loadout, in one command:
#
#   curl -fsSL https://raw.githubusercontent.com/josemiguelo/.dotfiles/master/bootstrap.sh | sh -s -- <machine>
#
# <machine> names a machine the repo declares (machine "<machine>" in
# machines/<machine>.loadout.hcl, compiled into loadout.lock.json) and becomes the
# hostname, so loadout, chezmoi's templates and the state file all agree on
# it. The order is the point: the hostname before the first apply (templates
# rendered for an unknown host get the defaults, e.g. omarchy: false), the
# dotfiles before setup-new-machine (its scripts read the applied configs).
#
#   1. the lock declares <machine> (asked over https, before any change)
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
# A machine whose data says omalauncher (Arch inside the omalauncher Android
# launcher: proot, root without sudo, no systemd) takes its own way through
# the same steps: a full pacman sync first, git and chezmoi from pacman, the
# name in /etc/hostname (proot can't set the kernel's; loadout gets it from
# LOADOUT_MACHINE), no ownership to give back, and sudo installed before
# setup-new-machine, which asks for it before any plan that runs it.
#
# A machine of a private child repo of this one (loadout's contract 18: the
# work laptop's, which builds on these dotfiles) takes --child <ssh url>: the
# child declares it, so this repo's lock isn't asked; its hostname stays the
# one its IT gave it, the name going in ~/.config/loadout/machine and the
# child's checkout in ~/.config/loadout/repo (~/.zshenv exports both); the
# child is cloned over ssh before the first apply (this repo's templates read
# its machine through LOADOUT_REPO), so the machine's ssh key must already be
# on GitHub; and loadout sets up the child, which runs this repo's recipes.
#
# Safe to run again: every step skips what's done. --dry-run prints the
# commands without running them.
# usage: bootstrap.sh [--dry-run] <machine> [--child <ssh url>]
set -eu

GH=josemiguelo/.dotfiles
RAW=https://raw.githubusercontent.com/$GH/master
REPO=$HOME/.local/share/chezmoi
LOADOUT_INSTALL=https://raw.githubusercontent.com/josemiguelo/loadout/master/install.sh

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { printf 'bootstrap: %s\n' "$*" >&2; exit 1; }
# fetch_run <url> [args…]: the installer script at url, downloaded whole
# first and then run with args. A failed download stops here with curl's
# error; piped or substituted, it would run an empty script that succeeds.
fetch_run() {
  _fr=$(mktemp)
  curl -fsSL "$1" -o "$_fr" || { rm -f "$_fr"; die "couldn't download $1"; }
  shift
  _rc=0
  sh "$_fr" "$@" || _rc=$?
  rm -f "$_fr"
  return "$_rc"
}

run() {
  printf '  + %s\n' "$*"
  [ -n "$DRY" ] || "$@"
}

main() {
  DRY=
  if [ "${1:-}" = --dry-run ]; then DRY=1; shift; fi
  MACHINE=${1:-}
  [ -n "$MACHINE" ] || die "usage: bootstrap.sh [--dry-run] <machine> [--child <ssh url>]  (a machine in https://github.com/$GH/tree/master/machines)"
  CHILD=
  if [ "${2:-}" = --child ]; then CHILD=${3:-}; [ -n "$CHILD" ] || die "--child needs the child repo's ssh url"; fi
  OS=$(uname -s)
  OMARCHY=
  command -v omarchy >/dev/null 2>&1 && OMARCHY=1
  # Set below from this repo's lock; a child repo's machine is never the phone.
  OMALAUNCHER=

  say "1. machine $MACHINE"
  if [ -n "$CHILD" ]; then
    echo "  declared by the child repo $CHILD"
  else
  # The lock's machines, one per line: the keys of its "machines" object,
  # which loadout writes pretty-printed, two spaces per level.
  machines=$(curl -fsSL "$RAW/loadout.lock.json" 2>/dev/null |
    awk '/^    "machines": [{]/ { m = 1; next } m && /^    [}]/ { exit } m && /^      "[^"]*": [{]/ { sub(/^ *"/, ""); sub(/".*/, ""); print }')
  if ! printf '%s\n' "$machines" | grep -qx "$MACHINE"; then
    cat >&2 <<EOF
bootstrap: $GH declares no machine $MACHINE (it has: $(printf '%s ' $machines)).
A machine new to the repo is declared first, extending its profiles, in
machines/$MACHINE.loadout.hcl, e.g.
  # MacBookPro16,1 (T2) running Omarchy.
  machine "$MACHINE" { extends = [profile.t2-macbook] }
Then loadout compile, commit and push (the lock too), and run this again.
EOF
    exit 1
  fi
  # Its omalauncher flag, from its table in the templates' data (written by
  # loadout compile, pretty-printed like the lock: four spaces deeper).
  DATA=$(curl -fsSL "$RAW/loadouts/.chezmoidata/loadout.json" 2>/dev/null || true)
  flag() {
    printf '%s\n' "$DATA" |
      awk -v key="      \"$MACHINE\": {" -v want="        \"$1\": true" '$0 == key { m = 1; next } m && /^      [}]/ { exit } m && index($0, want) == 1 { print; exit }' |
      grep -q .
  }
  flag omalauncher && OMALAUNCHER=1
  fi

  say "2. git and chezmoi"
  if [ -n "$OMALAUNCHER" ]; then
    # Its rootfs may come without package lists, and installing against lists
    # newer than the system is a partial upgrade: a full sync first.
    run pacman -Syu --noconfirm
  elif [ -n "$OMARCHY" ] && [ ! -s /var/lib/pacman/sync/core.db ]; then
    # Omarchy 4's offline ISO leaves pacman without its online package
    # lists, so `omarchy pkg add` finds nothing; its pacman hook refuses a
    # direct -Syu, and `omarchy update -y` syncs them unattended.
    run omarchy update -y
  fi
  command -v git >/dev/null 2>&1 && { command -v chezmoi >/dev/null 2>&1 || [ -x "$HOME/.local/bin/chezmoi" ]; } &&
    echo "  present"
  if ! command -v git >/dev/null 2>&1; then
    if [ -n "$OMARCHY" ]; then run omarchy pkg add git
    elif [ -n "$OMALAUNCHER" ]; then run pacman -S --needed --noconfirm git
    elif [ "$OS" = Darwin ]; then run xcode-select --install; die "install the command line tools, then run this again"
    elif command -v dnf >/dev/null 2>&1; then run sudo dnf install -y git
    else die "install git, then run this again"
    fi
  fi
  if ! command -v chezmoi >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/chezmoi" ]; then
    if [ -n "$OMARCHY" ]; then run omarchy pkg add chezmoi
    elif [ -n "$OMALAUNCHER" ]; then run pacman -S --needed --noconfirm chezmoi
    else run fetch_run https://get.chezmoi.io -b "$HOME/.local/bin"
    fi
  fi
  PATH=$HOME/.local/bin:$PATH

  say "3. hostname"
  if [ -n "$CHILD" ]; then
    # Its IT's hostname stays; the name is loadout's alone.
    NAMEFILE=$HOME/.config/loadout/machine
    if [ "$(cat "$NAMEFILE" 2>/dev/null)" != "$MACHINE" ]; then
      run mkdir -p "$(dirname "$NAMEFILE")"
      run sh -c 'printf "%s\n" "$1" >"$2"' sh "$MACHINE" "$NAMEFILE"
    else
      echo "  already $MACHINE (in $NAMEFILE)"
    fi
    # chezmoi's first apply runs before any zsh reads that file.
    export LOADOUT_MACHINE="$MACHINE"
  elif [ -n "$OMALAUNCHER" ]; then
    # Where chezmoi reads it; the first one is kept beside it.
    if [ "$(cat /etc/hostname 2>/dev/null)" != "$MACHINE" ]; then
      if [ -e /etc/hostname ] && [ ! -e /etc/hostname.pre-loadout ]; then
        run cp -p /etc/hostname /etc/hostname.pre-loadout
      fi
      run sh -c 'printf "%s\n" "$1" >/etc/hostname' sh "$MACHINE"
    else
      echo "  already $MACHINE"
    fi
  else
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
  fi

  say "4. ~/.local ownership"
  if [ -n "$OMALAUNCHER" ]; then
    echo "  all root's, as everything there"
  elif [ -d "$HOME/.local" ] && [ -n "$(find "$HOME/.local" ! -user "$(id -u)" -print -quit 2>/dev/null)" ]; then
    run sh -c 'find "$HOME/.local" ! -user "$(id -u)" -exec sudo chown "$(id -u):$(id -g)" {} +'
  else
    echo "  all yours"
  fi

  say "5. dotfiles"
  LREPO=$REPO
  if [ -n "$CHILD" ]; then
    # Bare, with its default branch's worktree, as bare-repos clones; its
    # folder drops a leading dot (.dotfiles-work lands in dotfiles-work).
    name=$(basename "$CHILD" .git)
    dir=$HOME/Repos/gh/josemiguelo/${name#.}
    if [ ! -d "$dir" ]; then
      ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1 | grep -q "successfully authenticated" || [ -n "$DRY" ] ||
        die "the child repo is private: put this machine's ssh key on GitHub first (ssh-keygen -t ed25519, then gh ssh-key add ~/.ssh/id_ed25519.pub), then run this again"
      run git clone --quiet --bare "$CHILD" "$dir"
      run git -C "$dir" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
      run git -C "$dir" fetch --quiet origin
    fi
    # Its hooks, as this repo's (a commit whose lock is stale is refused).
    run git -C "$dir" config core.hooksPath .githooks
    branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null || echo main)
    [ -d "$dir/all_worktrees/$branch" ] || run git -C "$dir" worktree add --quiet "$dir/all_worktrees/$branch" "$branch"
    LREPO=$dir/all_worktrees/$branch
    run sh -c 'printf "%s\n" "$1" >"$2"' sh "$LREPO" "$HOME/.config/loadout/repo"
    export LOADOUT_REPO="$LREPO"
  fi
  run chezmoi init --apply "https://github.com/$GH.git"
  # The repo's hooks (.githooks/pre-commit refuses manifests committed without
  # their compiled lock).
  run git -C "$REPO" config core.hooksPath .githooks

  say "6. loadout"
  if [ ! -x "$HOME/.local/bin/loadout" ] && ! command -v loadout >/dev/null 2>&1; then
    run fetch_run "$LOADOUT_INSTALL"
  else
    echo "  installed"
  fi

  say "7. loadout setup-new-machine"
  if [ -n "$OMALAUNCHER" ]; then
    # Its rootfs ships without sudo, which pacman's installer runs.
    run env LOADOUT_REPO="$REPO" loadout --repo "$REPO" --machine "$MACHINE" install sudo --yes
  fi
  if [ -n "$CHILD" ]; then
    # The child's own dotfiles; this repo's are applied above.
    run env LOADOUT_REPO="$LREPO" loadout --repo "$LREPO" --machine "$MACHINE" apply
  fi
  run env LOADOUT_REPO="$LREPO" \
    MISE_IGNORED_CONFIG_PATHS="$REPO:$HOME/.local/share/chezmoi__worktrees" \
    loadout --repo "$LREPO" --machine "$MACHINE" setup-new-machine --yes

  say "done: $MACHINE"
  if [ -n "$OMALAUNCHER" ]; then
    echo "Open a new terminal: the login shell is zsh now, with LOADOUT_MACHINE set."
    echo "Then look at git status in $REPO: setup tracks launcher files the repo"
    echo "didn't have; keep or drop them, then loadout sync."
  else
    echo "Reboot now: the login shell, new groups (docker, libvirt), the rebuilt"
    echo "initramfs and the session's environment only apply after it."
  fi
}

# Last, with the terminal as input: under `curl | sh` the script itself is
# stdin, and sudo, gh's login and the installers need a terminal to ask on.
if [ -t 0 ]; then main "$@"; else main "$@" </dev/tty; fi
