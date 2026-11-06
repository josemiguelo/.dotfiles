#!/bin/sh
# The 1Password CLI reaching an account through the desktop app (Settings →
# Developer → "Integrate with 1Password CLI"). Steps that read secrets with
# `op` (intentional-sync, Intentional's provision-android.sh) run after this.
# `check` asks only for the accounts list, which needs no approval prompt:
# it says the integration is set up, not that the app is unlocked right now
# (the steps that read secrets say so when it isn't). The app's switch can't
# be flipped from here, so `install` says where it is.
# Modes: `check` / `install` (default).
set -eu

ready() {
  command -v op >/dev/null 2>&1 &&
    op account list --format=json 2>/dev/null | jq -e 'length > 0' >/dev/null 2>&1
}

case "${1:-install}" in
check)
  ready
  ;;
install)
  ready && exit 0
  cat >&2 <<'MSG'
The 1Password CLI isn't connected to an account. In the 1Password app:
  Settings → Developer → turn on "Integrate with 1Password CLI"
(the app must be running and signed in). Then `op vault list` asks once to approve.
MSG
  exit 1
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
