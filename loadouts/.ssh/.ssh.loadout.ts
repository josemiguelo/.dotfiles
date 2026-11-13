// ssh: this machine's key and agent, on any OS. Omarchy's ssh server is
// .omarchy-sshd.loadout.ts, beside this file.
import { args, script } from "loadout";
import { gh } from "../private_dot_config/.gh.loadout.ts";
import { miseTools } from "../private_dot_config/mise/.mise.loadout.ts";

export const setupSsh = script("setup-ssh", {
  description: "machine ssh key and agent auto-add config",
  file: ".loadout/setup-ssh.ts",
  // The agent-unit clause is for Linux with systemd; uname short-circuits it
  // on macOS, and /run/systemd/system where systemd isn't running
  // (a container).
  check: [
    "test -f $HOME/.ssh/$1",
    "grep -q 'AddKeysToAgent yes' $HOME/.ssh/config",
    "ssh-keygen -F github.com -f $HOME/.ssh/known_hosts >/dev/null",
    'test "$(uname -s)" != Linux || test ! -d /run/systemd/system || systemctl --user -q is-enabled ssh-agent.socket',
  ],
});

// The key on GitHub, titled with the machine's name. Logs gh in through the
// browser when needed: the one browser step, last.
export const githubSshKey = script("github-ssh-key", {
  description: "this machine's ssh key on GitHub",
  managedBy: ".loadout/github-ssh-key.ts",
  runAfter: [setupSsh, miseTools, gh],
});

// The machine's key, on disk and on GitHub: one call instead of the same two
// runs in every machine that has a key.
export const sshKey = (name: string) => [args(setupSsh, name), args(githubSshKey, name)];
