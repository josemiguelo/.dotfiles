#!/bin/sh
# The machine's name (LOADOUT_MACHINE, which loadout sets for its scripts)
# in /etc/hostname, where chezmoi's .chezmoi.hostname comes from, and in
# ~/.bashrc with the repo's path, so every later loadout run in a shell knows
# both. The first /etc/hostname is kept as /etc/hostname.pre-loadout.
# Modes: `check` / `install` (default).
set -eu

NAME=${LOADOUT_MACHINE:?LOADOUT_MACHINE is unset: run loadout with --machine}
RC="$HOME/.bashrc"
# shellcheck disable=SC2016 # $HOME stays for the shell that reads ~/.bashrc
LINES="export LOADOUT_MACHINE=$NAME
export LOADOUT_REPO=\"\$HOME/.local/share/chezmoi\""

in_rc() {
  [ -f "$RC" ] || return 1
  printf '%s\n' "$LINES" | while IFS= read -r line; do
    grep -qxF -- "$line" "$RC" || return 1
  done
}

case "${1:-install}" in
check)
  [ "$(cat /etc/hostname 2>/dev/null)" = "$NAME" ] && in_rc
  ;;
install)
  if [ "$(cat /etc/hostname 2>/dev/null)" != "$NAME" ]; then
    [ -e /etc/hostname.pre-loadout ] || cp -p /etc/hostname /etc/hostname.pre-loadout 2>/dev/null || true
    printf '%s\n' "$NAME" >/etc/hostname
  fi
  if ! in_rc; then
    # Earlier names' lines go, so the last export can't lose to a stale one.
    [ -f "$RC" ] && sed -i '/^export LOADOUT_MACHINE=/d; /^export LOADOUT_REPO=/d; /^# loadout: this machine/d' "$RC"
    printf '\n# loadout: this machine (gethostname says "localhost" under proot) and its config repo\n%s\n' "$LINES" >>"$RC"
  fi
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
