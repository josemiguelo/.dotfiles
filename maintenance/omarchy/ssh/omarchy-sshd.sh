#!/bin/sh
# SSH access to this machine, set up the native way:
# omarchy-setup-security-sshd enables sshd, opens 22/tcp in ufw (rate
# limited, comment "omarchy-sshd"), authorizes a key and then turns password
# logins off (sshd_config.d/10-omarchy-hardening.conf). Its rule opens 22 to
# any address, so after it the rule is narrowed to the private IPv4 ranges:
# a LAN, a VM's bridge, not the internet (a café's Wi-Fi is private too, so
# the keys are still what keeps others out). It authorizes one key
# per call, so it runs once per trusted key this machine doesn't trust yet.
# Trusted are the keys of the GitHub account gh is logged in to whose titles
# are named (github-ssh-key titles a machine's key with the machine's name),
# not all of them: a key added to the account later, by a new machine or by
# someone else, gets no shell here until it's named.
# ~/.ssh/authorized_keys mirrors them: a key deleted on GitHub, or no longer
# named, loses access here on the next run. GitHub serves keys without their
# comments, so no email ends up in authorized_keys.
# The check reads only world-readable files and asks gh, so `loadout status`
# needs no sudo for it.
# usage: omarchy-sshd.sh [check] <key-title>...
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
[ "$#" -gt 0 ] || { echo "usage: omarchy-sshd.sh [check] <key-title>..." >&2; exit 2; }
# gh from mise's shims, where Omarchy's conf.d/omarchy.toml installs it.
export PATH="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims:$PATH"

AUTHORIZED_KEYS=$HOME/.ssh/authorized_keys
HARDENING=/etc/ssh/sshd_config.d/10-omarchy-hardening.conf
RULES=/etc/ufw/user.rules
RULES6=/etc/ufw/user6.rules
PRIVATE="10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"
HEX=$(printf '%s' omarchy-sshd | od -An -tx1 | tr -d ' \n')

# The trusted keys (titles as arguments), "type base64" per line: the part of
# a key that identifies it.
github_keys() {
  all=$(gh api user/keys --paginate --jq '.[] | "\(.title)\t\(.key)"') ||
    { echo "could not list the account's keys (gh api user/keys)" >&2; return 1; }
  keys=$(printf '%s\n' "$all" | while IFS="$(printf '\t')" read -r title key; do
    for trusted in "$@"; do
      [ "$title" = "$trusted" ] && printf '%s\n' "$key"
    done
  done | awk 'NF >= 2 { print $1, $2 }' | sort -u)
  [ -n "$keys" ] || { echo "none of the trusted keys is on GitHub: $*" >&2; return 1; }
  printf '%s\n' "$keys"
}

authorized() {
  [ -f "$AUTHORIZED_KEYS" ] || return 0
  awk '/^(ssh|ecdsa|sk-)/ { print $1, $2 }' "$AUTHORIZED_KEYS" | sort -u
}

# 22 open from each private range, and from nowhere else (Omarchy's rule,
# from any address, IPv6's included).
firewall_scoped() {
  for range in $PRIVATE; do
    grep -qxF "### tuple ### limit tcp 22 0.0.0.0/0 any $range in comment=$HEX" "$RULES" 2>/dev/null || return 1
  done
  ! grep -qE "^### tuple ### limit tcp 22 (0\.0\.0\.0/0 any 0\.0\.0\.0/0|::/0 any ::/0) in comment=$HEX\$" "$RULES" "$RULES6" 2>/dev/null
}

scope_firewall() {
  for range in $PRIVATE; do
    sudo ufw limit from "$range" to any port 22 proto tcp comment omarchy-sshd >/dev/null
  done
  # Omarchy's own rule; deleting it drops its IPv6 twin too.
  sudo ufw delete limit 22/tcp >/dev/null 2>&1 || true
  sudo ufw reload >/dev/null
}

server_ready() {
  systemctl -q is-enabled sshd.service && systemctl -q is-active sshd.service &&
    firewall_scoped && [ -f "$HARDENING" ]
}

case "$MODE" in
check)
  want=$(github_keys "$@")
  server_ready && [ "$want" = "$(authorized)" ]
  ;;
install)
  want=$(github_keys "$@")
  have=$(authorized)
  missing=$(printf '%s\n' "$want" | while read -r key; do
    printf '%s\n' "$have" | grep -qxF "$key" || printf '%s\n' "$key"
  done)
  # Nothing missing but the server isn't fully set up: one call with a key
  # it already trusts redoes the setup steps.
  if [ -z "$missing" ] && ! server_ready; then
    missing=$(printf '%s\n' "$want" | head -n1)
  fi
  # A for loop, not `| while read`: the setup script's sudo and pacman
  # keep the terminal as stdin.
  IFS='
'
  for key in $missing; do
    omarchy-setup-security-sshd --key="$key"
  done
  unset IFS
  firewall_scoped || scope_firewall
  # Drop keys GitHub no longer has. Only after the additions: the hardening
  # step refuses to turn passwords off with an empty authorized_keys.
  tmp=$(mktemp)
  printf '%s\n' "$want" | awk 'NR == FNR { keep[$1 " " $2] = 1; next }
    !/^(ssh|ecdsa|sk-)/ || ($1 " " $2) in keep' - "$AUTHORIZED_KEYS" > "$tmp"
  cat "$tmp" > "$AUTHORIZED_KEYS"
  rm -f "$tmp"
  server_ready && [ "$want" = "$(authorized)" ] ||
    { echo "sshd setup or authorized_keys doesn't match GitHub after install" >&2; exit 1; }
  ;;
esac
