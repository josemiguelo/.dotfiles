// The ssh agent setup-ssh.ts and github-ssh-key.ts reach, and the commands
// that need a terminal (a passphrase, a browser login).
import { statSync } from "node:fs";
import { $, read } from "#loadout";

/**
 * argv on this terminal, with this process's environment as it is now: a
 * Bun.spawn left to itself gets the environment the script started with, so
 * an SSH_AUTH_SOCK or PATH set since would be lost. Throws when it fails.
 */
export async function onTerminal(...argv: string[]) {
  const bin = Bun.which(argv[0], { PATH: process.env.PATH }) ?? argv[0];
  const code = await Bun.spawn([bin, ...argv.slice(1)], { env: process.env, stdio: ["inherit", "inherit", "inherit"] }).exited;
  if (code !== 0) throw new Error(`${argv.join(" ")} failed (exit ${code})`);
}

/**
 * An agent this script's ssh and ssh-add reach. setup-ssh makes keys without
 * a passphrase now, but one made earlier has one, and ssh never asks for it
 * under BatchMode, so the scripts that use the key go through an agent: the
 * dotfiles' (openssh's ssh-agent.socket user unit on Linux with systemd,
 * launchd's on macOS) when it's reachable, else one of the script's own,
 * which dies with it (where systemd isn't running there's no unit). Set in
 * process.env, which every later $`…` and onTerminal command gets.
 */
export async function sshAgentUp() {
  // 0: it holds keys, 1: none yet, 2: no agent there.
  if ((await $`ssh-add -l`.quiet().nothrow()).exitCode !== 2) return;
  const sock = `${process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid!()}`}/ssh-agent.socket`;
  if (statSync(sock, { throwIfNoEntry: false })?.isSocket()) {
    process.env.SSH_AUTH_SOCK = sock;
    return;
  }
  const started = (await $`ssh-agent -s`.quiet().text()).match(/SSH_AUTH_SOCK=([^;]+);[\s\S]*SSH_AGENT_PID=(\d+);/);
  if (!started) throw new Error("ssh-agent didn't say where it listens");
  process.env.SSH_AUTH_SOCK = started[1];
  process.env.SSH_AGENT_PID = started[2];
  // Stopped when the script exits: nothing else reaches it (each script loads
  // the key into its own), and checks run on every status. What `ssh-agent
  // -k` does, a SIGTERM to its pid, from the exit handler, which can't wait
  // on a command.
  const pid = Number(started[2]);
  process.on("exit", () => {
    try {
      process.kill(pid, "SIGTERM");
    } catch {}
  });
}

/**
 * key.pub's key part (its second field), "" when there's no key.pub: nothing
 * then matches it (sh's `grep -F ""` matched every line).
 */
export const publicKey = async (key: string) => (await read(`${key}.pub`)).split("\n")[0].split(" ")[1] ?? "";

/** The agent holds key, matched by its public half. */
export async function sshKeyLoaded(key: string) {
  const mine = await publicKey(key);
  return mine !== "" && (await $`ssh-add -L`.quiet().nothrow()).stdout.toString().includes(mine);
}
