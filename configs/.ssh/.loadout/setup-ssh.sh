#!/bin/sh
# Machine ssh key + agent auto-add config.
# usage: setup-ssh.sh <key-name>   (key lands at ~/.ssh/<key-name>)
set -eu

if [ -z "${1:-}" ]; then
  echo "error: no key name given" >&2
  echo "usage: setup-ssh.sh <key-name>" >&2
  exit 2
fi
SSH_KEY="$HOME/.ssh/$1"
. "$LOADOUT_REPO/lib/ssh-agent.sh"

# The agent itself. The dotfiles point SSH_AUTH_SOCK at the socket of
# openssh's ssh-agent.socket user unit, which Fedora installs but never
# enables for a new account — without this, ssh-add fails with "Error
# connecting to agent". (macOS runs its own agent via launchd; without
# systemd, as in omalauncher's proot, there's no unit to enable.) First, so
# a new key goes into it.
if [ "$(uname -s)" = "Linux" ] && [ -d /run/systemd/system ] && ! systemctl --user -q is-enabled ssh-agent.socket 2>/dev/null; then
  systemctl --user enable --now ssh-agent.socket
fi

# A new key has a passphrase (ssh-keygen asks for it): the key pushes to
# GitHub, and on the T2 logs in over ssh, so a copy of the file mustn't be
# enough. Into the agent right away, so github-ssh-key's ssh finds it; from
# then on AddKeysToAgent asks once per login. Commented with the machine's
# name, as github-ssh-key titles it on GitHub.
if [ ! -f "$SSH_KEY" ]; then
  ssh-keygen -t ed25519 -C "${LOADOUT_MACHINE:-$(hostname -s)}" -f "$SSH_KEY"
  ssh_agent_up
  ssh-add "$SSH_KEY"
fi

# GitHub's host key, so the first ssh clone/fetch (dotfiles, loadout sync)
# never stops at an interactive "authenticity of host" prompt.
KNOWN_HOSTS="$HOME/.ssh/known_hosts"
touch "$KNOWN_HOSTS"
chmod 600 "$KNOWN_HOSTS"
if ! ssh-keygen -F github.com -f "$KNOWN_HOSTS" >/dev/null; then
  ssh-keyscan -t ed25519 github.com 2>/dev/null >>"$KNOWN_HOSTS"
fi

SSH_CONFIG="$HOME/.ssh/config"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"
if ! grep -q "AddKeysToAgent yes" "$SSH_CONFIG"; then
  printf '\nHost *\n    AddKeysToAgent yes\n    IdentityFile %s\n' "$SSH_KEY" >>"$SSH_CONFIG"
fi
