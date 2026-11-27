// ssh: this machine's key and agent, on any OS. Omarchy's ssh server is
// omarchy-sshd.loadout.ts, beside this file.
import { script } from "loadout";
import { gh } from "../gh/gh.loadout.ts";
import { miseTools } from "../mise/mise.loadout.ts";

export const setupSsh = script("setup-ssh", {
  description: "machine ssh key and agent auto-add config",
  module: () => import("./.loadout/setup-ssh.ts"),
  rules: () => import("./.loadout/setup-ssh.rules.ts"),
});

// The key on GitHub, titled with the machine's name. Logs gh in through the
// browser when needed: the one browser step, last.
export const githubSshKey = script("github-ssh-key", {
  description: "this machine's ssh key on GitHub",
  module: () => import("./.loadout/github-ssh-key.ts"),
  rules: () => import("./.loadout/github-ssh-key.rules.ts"),
  runAfter: [setupSsh, miseTools, gh],
});

// The machine's key, on disk and on GitHub: one call instead of the same two
// runs in every machine that has a key.
export const sshKey = (name: string) => [setupSsh({ key: name }), githubSshKey({ key: name })];
