# ssh_agent_up: an agent this script's ssh and ssh-add reach. The machine's
# key has a passphrase, and ssh never asks for one under BatchMode, so the
# scripts that use the key go through an agent: the dotfiles' (openssh's
# ssh-agent.socket user unit on Linux with systemd, launchd's on macOS) when
# it's reachable, else one of the script's own, which dies with it
# (omalauncher's proot has no unit).
ssh_agent_up() {
  _sa_rc=0
  ssh-add -l >/dev/null 2>&1 || _sa_rc=$?
  # 0: it holds keys, 1: none yet, 2: no agent there.
  [ "$_sa_rc" -ne 2 ] && return 0
  _sa_sock=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket
  if [ -S "$_sa_sock" ]; then
    export SSH_AUTH_SOCK="$_sa_sock"
  else
    eval "$(ssh-agent -s)" >/dev/null
  fi
}

# ssh_key_loaded <key>: the agent holds <key>, matched by its public half.
ssh_key_loaded() {
  ssh-add -L 2>/dev/null | grep -qF -- "$(cut -d' ' -f2 "$1.pub")"
}
