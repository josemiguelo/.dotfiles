#!/bin/sh
# The 1Password CLI reaching an account through the desktop app (Settings →
# Developer → "Integrate with 1Password CLI"). Steps that read secrets with
# `op` (intentional-sync, kait2en-dev, bcm-firmware) run after this.
# `check` asks only for the accounts list, which needs no approval prompt:
# it says the integration is set up, not that the app is unlocked right now.
# The app's switch can't be flipped from here, so `install` waits on purpose:
# it says what to do, polls until the integration shows up, then runs one
# `op vault list` in the open so its approval prompt is answered here, not
# behind a later step's hidden one (op keeps that approval for a while, so the
# steps after this read without asking again). It gives up after
# ONEPASSWORD_WAIT seconds (default 900; 0 doesn't wait).
# Modes: `check` / `install` (default).
set -eu

WAIT=${ONEPASSWORD_WAIT:-900}
FLAG=--force-device-scale-factor=1

ready() {
  command -v op >/dev/null 2>&1 &&
    op account list --format=json 2>/dev/null | jq -e 'length > 0' >/dev/null 2>&1
}

# The app has to be running for the integration; Omarchy's installer opens it,
# but it may have been closed since. Started detached, unscaled as everywhere.
open_app() {
  command -v 1password >/dev/null 2>&1 || return 0
  pgrep -x 1password >/dev/null 2>&1 && return 0
  [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] || return 0
  if command -v uwsm-app >/dev/null 2>&1; then
    setsid uwsm-app -- 1password "$FLAG" >/dev/null 2>&1 &
  else
    setsid 1password "$FLAG" >/dev/null 2>&1 &
  fi
}

approve() {
  echo "onepassword-cli: approve the prompt in the 1Password app (unlock it first if asked)…" >&2
  op vault list >/dev/null || {
    echo "onepassword-cli: 1Password didn't let the CLI in (locked, or the prompt was denied)" >&2
    exit 1
  }
  echo "onepassword-cli: the CLI is connected" >&2
}

case "${1:-install}" in
check)
  ready
  ;;
install)
  if ready; then approve; exit 0; fi
  command -v op >/dev/null 2>&1 || { echo "onepassword-cli: op isn't installed" >&2; exit 1; }
  open_app
  cat >&2 <<MSG

==> Waiting for the 1Password CLI integration (up to ${WAIT}s). In the 1Password app:
      1. sign in to your account
      2. Settings → Developer → turn on "Integrate with 1Password CLI"
    This goes on by itself once it's on.
MSG
  deadline=$(($(date +%s) + WAIT))
  last=
  until ready; do
    now=$(date +%s)
    if [ "$now" -ge "$deadline" ]; then
      echo "onepassword-cli: gave up waiting after ${WAIT}s; turn the integration on, then run this again" >&2
      exit 1
    fi
    left=$(((deadline - now) / 60))
    [ "$left" = "$last" ] || { echo "    still waiting (about ${left}m left)…" >&2; last=$left; }
    sleep 3
  done
  echo "onepassword-cli: integration is on" >&2
  approve
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
