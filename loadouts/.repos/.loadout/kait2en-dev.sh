#!/bin/sh
# The KaiT2en -> Omarchy development setup (docs/t2-macbook.md), on top of the
# bare clones bare-repos makes of t2-arch-packages, omarchy and omarchy-iso:
#
# - the forks (omarchy, omarchy-iso): an `upstream` remote (omacom/<repo>) and
#   the t2-kait2en branch checked out in all_worktrees/t2-kait2en, where the
#   T2 work lives and the ISO is built from;
# - clones kait2en-sync and the ISO build read: KaiT2en upstream and
#   omacom/omarchy-pkgs, in ~/Repos/gh/<owner>/<repo> like gclone's;
# - libvfio-user with its gpio-pci-idio-16 sample built, the fake-hardware
#   server of `omarchy-iso-test --fake-pci` (its build deps are the machine's
#   omarchy_iso_test_deps);
# - the [t2-arch-packages] signing key in gpg, from the 1Password item
#   "kait2en" (Personal vault), trusted ultimately, so kait2en-sync can sign;
# - a daily user timer running `kait2en-sync notify`: a desktop notification
#   when KaiT2en changes a package, or when a new linux-omarchy would break a
#   T2 module (before Omarchy ships it).
#
# check: all of the above in place (says what's missing). install: whichever
# isn't. Existing clones are only fetched, never reset.
# Modes: `check` / `install` (default).
set -eu

REPOS=$HOME/Repos/gh
BRANCH=t2-kait2en
FPR=077D8295CCF834D3F5EC25F70506B72C34EB162F
KEY_REF="op://Personal/kait2en/t2-arch-packages-signing-key.asc"
VFIO=$REPOS/nutanix/libvfio-user
VFIO_BIN=$VFIO/build/samples/gpio-pci-idio-16
UNITS=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
SYNC=$REPOS/josemiguelo/t2-arch-packages/all_worktrees/main/bin/kait2en-sync

service_text() {
  cat <<EOF
# Managed by loadout (kait2en-dev).
[Unit]
Description=Check KaiT2en and linux-omarchy for changes to the T2 packages

[Service]
Type=oneshot
ExecStart=$SYNC notify
EOF
}

timer_text() {
  cat <<'EOF'
# Managed by loadout (kait2en-dev).
[Unit]
Description=Daily check of KaiT2en and linux-omarchy for the T2 packages

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=30min

[Install]
WantedBy=timers.target
EOF
}

fork_dir() { echo "$REPOS/josemiguelo/$1"; }

fork_ok() {
  dir=$(fork_dir "$1")
  [ "$(git -C "$dir" config --get remote.upstream.url 2>/dev/null)" = "https://github.com/omacom/$1.git" ] &&
    [ -d "$dir/all_worktrees/$BRANCH" ]
}

fork_install() {
  dir=$(fork_dir "$1")
  [ -d "$dir" ] || { echo "kait2en-dev: $dir missing (bare-repos clones it)" >&2; return 1; }
  if git -C "$dir" remote get-url upstream >/dev/null 2>&1; then
    git -C "$dir" remote set-url upstream "https://github.com/omacom/$1.git"
  else
    git -C "$dir" remote add upstream "https://github.com/omacom/$1.git"
  fi
  git -C "$dir" config remote.upstream.pushurl no_push
  git -C "$dir" fetch --quiet origin
  git -C "$dir" fetch --quiet upstream
  if [ ! -d "$dir/all_worktrees/$BRANCH" ]; then
    if git -C "$dir" show-ref --verify --quiet "refs/heads/$BRANCH"; then
      git -C "$dir" worktree add --quiet "$dir/all_worktrees/$BRANCH" "$BRANCH"
    else
      git -C "$dir" worktree add --quiet -b "$BRANCH" "$dir/all_worktrees/$BRANCH" "origin/$BRANCH"
    fi
    git -C "$dir/all_worktrees/$BRANCH" branch --quiet --set-upstream-to="origin/$BRANCH" "$BRANCH"
    echo "kait2en-dev: $1's $BRANCH checked out in $dir/all_worktrees/$BRANCH"
  fi
}

clone_ok() { [ -d "$REPOS/$1/.git" ]; }

clone_install() {
  if clone_ok "$1"; then
    git -C "$REPOS/$1" fetch --quiet origin || true
  else
    echo "kait2en-dev: cloning $1"
    mkdir -p "$(dirname "$REPOS/$1")"
    git clone --quiet "https://github.com/$1.git" "$REPOS/$1"
  fi
}

vfio_ok() { [ -x "$VFIO_BIN" ]; }

vfio_install() {
  clone_install nutanix/libvfio-user
  [ -d "$VFIO/build" ] || (cd "$VFIO" && meson setup build . -Ddefault_library=static >/dev/null)
  ninja -C "$VFIO/build" samples/gpio-pci-idio-16 >/dev/null
}

key_ok() { gpg --list-secret-keys "$FPR" >/dev/null 2>&1; }

key_install() {
  op vault list >/dev/null 2>&1 || {
    echo "kait2en-dev: 1Password isn't unlocked for the CLI: unlock the app (and approve its prompt), then run this again" >&2
    return 1
  }
  op read "$KEY_REF" | gpg --batch --quiet --import
  echo "$FPR:6:" | gpg --quiet --import-ownertrust
}

units_ok() {
  [ "$(cat "$UNITS/kait2en-sync.service" 2>/dev/null)" = "$(service_text)" ] &&
    [ "$(cat "$UNITS/kait2en-sync.timer" 2>/dev/null)" = "$(timer_text)" ] &&
    systemctl --user -q is-enabled kait2en-sync.timer 2>/dev/null
}

units_install() {
  mkdir -p "$UNITS"
  service_text > "$UNITS/kait2en-sync.service"
  timer_text > "$UNITS/kait2en-sync.timer"
  systemctl --user daemon-reload
  systemctl --user enable --now kait2en-sync.timer
}

case "${1:-install}" in
check)
  rc=0
  for repo in omarchy omarchy-iso; do fork_ok "$repo" || { echo "missing: $repo upstream remote or $BRANCH worktree"; rc=1; }; done
  for repo in kaiT2en/KaiT2en-Fedora omacom/omarchy-pkgs; do clone_ok "$repo" || { echo "missing: $repo"; rc=1; }; done
  vfio_ok || { echo "missing: $VFIO_BIN"; rc=1; }
  key_ok || { echo "missing: signing key $FPR"; rc=1; }
  units_ok || { echo "missing: kait2en-sync.timer"; rc=1; }
  exit "$rc"
  ;;
install)
  for repo in omarchy omarchy-iso; do fork_ok "$repo" || fork_install "$repo"; done
  for repo in kaiT2en/KaiT2en-Fedora omacom/omarchy-pkgs; do clone_install "$repo"; done
  vfio_ok || vfio_install
  key_ok || key_install
  units_ok || units_install
  exec "$0" check
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
