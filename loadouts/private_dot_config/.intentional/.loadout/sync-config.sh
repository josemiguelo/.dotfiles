#!/bin/sh
# Intentional's ~/.config/intentional/sync.json, written from the "Intentional
# sync" item in 1Password (Personal vault): the Firebase database and API key,
# the one account every device signs in as, and the encryption key, plus this
# machine's device name ($1, from the machine's run list), which must stay the
# same once the machine has synced. The file is readable by the user alone;
# writing it restarts the daemon, which reads it at start. `check` only reads
# the file, so it never asks 1Password anything.
# Usage: `sync-config.sh [check] <device name>` (loadout passes the machine's
# arguments after the mode; install has no mode word).
set -eu
. "$LOADOUT_REPO/loadouts/private_dot_config/.1password/.loadout/op-unlocked.sh"

mode=install
case "${1:-}" in check | install) mode=$1; shift ;; esac
device="${1:-}"
[ -n "$device" ] || { echo "usage: $0 [check] <device name>" >&2; exit 2; }

config="${XDG_CONFIG_HOME:-$HOME/.config}/intentional/sync.json"
item="op://Personal/Intentional sync"

ready() {
  [ -f "$config" ] && jq -e --arg device "$device" '
    .device == $device and
    ([.databaseUrl, .apiKey, .email, .password, .key] | all(type == "string" and length > 0))
  ' "$config" >/dev/null 2>&1
}

case "$mode" in
check)
  ready
  ;;
install)
  ready && exit 0
  # onepassword-cli checks the integration is set up; reading also needs the
  # app unlocked, which only shows now.
  op_unlocked intentional-sync || exit 1
  # Each read on its own line, so a failed one stops here (inside a command's
  # arguments it wouldn't), and nothing is written unless all came back.
  database_url=$(op read "$item/database url")
  api_key=$(op read "$item/api key")
  email=$(op read "$item/username")
  password=$(op read "$item/password")
  key=$(op read "$item/encryption key")
  for value in "$database_url" "$api_key" "$email" "$password" "$key"; do
    [ -n "$value" ] || { echo "1Password returned an empty field in \"Intentional sync\"" >&2; exit 1; }
  done
  umask 077
  mkdir -p "$(dirname "$config")"
  jq -n \
    --arg databaseUrl "$database_url" --arg apiKey "$api_key" --arg email "$email" \
    --arg password "$password" --arg key "$key" --arg device "$device" \
    '{databaseUrl: $databaseUrl, apiKey: $apiKey, email: $email, password: $password, key: $key, device: $device}' \
    >"$config.tmp"
  mv "$config.tmp" "$config"
  ready || { echo "wrote $config but it doesn't pass the check" >&2; exit 1; }
  systemctl --user try-restart intentional.service 2>/dev/null || true
  echo "Intentional syncs as \"$device\"" >&2
  ;;
esac
