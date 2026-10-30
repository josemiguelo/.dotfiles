# ssh: this machine's key and agent, on any OS. Omarchy's ssh server is
# .omarchy-sshd.loadout.hcl, beside this file.

script "setup-ssh" {
  description = "machine ssh key and agent auto-add config"
  file        = ".loadout/setup-ssh.sh"
  # The agent-unit clause is for Linux with systemd; uname short-circuits it
  # on macOS, and /run/systemd/system where systemd isn't running
  # (omalauncher's proot).
  check = [
    "test -f $HOME/.ssh/$1",
    "grep -q 'AddKeysToAgent yes' $HOME/.ssh/config",
    "ssh-keygen -F github.com -f $HOME/.ssh/known_hosts >/dev/null",
    "test \"$(uname -s)\" != Linux || test ! -d /run/systemd/system || systemctl --user -q is-enabled ssh-agent.socket",
  ]
}

# The key on GitHub, titled with the machine's name. Logs gh in through the
# browser when needed: the one browser step, last.
script "github-ssh-key" {
  description = "this machine's ssh key on GitHub"
  managed_by  = ".loadout/github-ssh-key.sh"
  run_after   = [script.setup-ssh, script.mise-tools, program.gh]
}

# The machine's key, on disk and on GitHub: one call instead of the same two
# runs in every machine that has a key.
function "ssh_key" {
  params = [name]
  result = [args(script.setup-ssh, name), args(script.github-ssh-key, name)]
}
