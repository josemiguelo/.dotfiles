// Machine ssh key + agent auto-add config.
import { appendFileSync, chmodSync, mkdirSync, statSync } from "node:fs";
import { hostname } from "node:os";
import { dirname } from "node:path";
import { $, succeeds, read } from "loadout/script";
import { onTerminal, sshAgentUp } from "#ssh";
import type { Options } from "./setup-ssh.rules.ts";

const HOME = process.env.HOME!;

const isDir = (path: string) => statSync(path, { throwIfNoEntry: false })?.isDirectory() ?? false;
const isFile = (path: string) => statSync(path, { throwIfNoEntry: false })?.isFile() ?? false;

/** sh's `touch` then `chmod 600`: the file there, its contents kept, private. */
function touchPrivate(path: string) {
  appendFileSync(path, "");
  chmodSync(path, 0o600);
}

const agentUnitNeeded = () => process.platform === "linux" && isDir("/run/systemd/system");

/**
 * The agent itself. The dotfiles point SSH_AUTH_SOCK at the socket of
 * openssh's ssh-agent.socket user unit, which a distro may install but never
 * enable for a new account — without this, ssh-add fails with "Error
 * connecting to agent". (macOS runs its own agent via launchd; without
 * systemd, as in a container, there's no unit to enable.)
 */
async function agentUnit() {
  if (!agentUnitNeeded()) return;
  if (await succeeds($`systemctl --user -q is-enabled ssh-agent.socket`)) return;
  await $`systemctl --user enable --now ssh-agent.socket`;
}

/**
 * A new key has no passphrase, so setup never stops to ask for one: the file
 * alone is the key (it pushes to GitHub, and on the T2 logs in over ssh),
 * kept safe by the disk's encryption and its 600 mode. Into the agent right
 * away all the same (no prompt without a passphrase). Commented with the
 * machine's name, as github-ssh-key titles it on GitHub. A key made earlier
 * with a passphrase keeps it (`ssh-keygen -p -f <key>` drops it).
 */
async function key(path: string) {
  if (isFile(path)) return;
  mkdirSync(dirname(path), { recursive: true });
  chmodSync(dirname(path), 0o700);
  const comment = process.env.LOADOUT_MACHINE || hostname().split(".")[0];
  await $`ssh-keygen -q -t ed25519 -N ${""} -C ${comment} -f ${path}`;
  await sshAgentUp();
  await onTerminal("ssh-add", path);
}

/**
 * GitHub's host key, so the first ssh clone/fetch (dotfiles, loadout machine sync)
 * never stops at an interactive "authenticity of host" prompt.
 */
async function knownHosts() {
  const file = `${HOME}/.ssh/known_hosts`;
  touchPrivate(file);
  if ((await $`ssh-keygen -F github.com -f ${file} > /dev/null`.nothrow()).exitCode === 0) return;
  // What it found is kept even when it fails, as sh's `>>` kept it.
  const scan = await $`ssh-keyscan -t ed25519 github.com`.quiet().nothrow();
  appendFileSync(file, scan.stdout);
  if (scan.exitCode !== 0) throw new Error(`ssh-keyscan github.com failed (exit ${scan.exitCode})`);
}

async function config(path: string) {
  const file = `${HOME}/.ssh/config`;
  touchPrivate(file);
  if ((await read(file)).includes("AddKeysToAgent yes")) return;
  appendFileSync(file, `\nHost *\n    AddKeysToAgent yes\n    IdentityFile ${path}\n`);
}

export async function check({ key: name }: Options) {
  return (
    isFile(`${HOME}/.ssh/${name}`) &&
    (await read(`${HOME}/.ssh/config`)).includes("AddKeysToAgent yes") &&
    (await succeeds($`ssh-keygen -F github.com -f ${HOME}/.ssh/known_hosts`)) &&
    // For Linux with systemd: elsewhere (macOS, a container) there's no unit.
    (!agentUnitNeeded() || (await succeeds($`systemctl --user -q is-enabled ssh-agent.socket`)))
  );
}

export async function install({ key: name }: Options) {
  const path = `${HOME}/.ssh/${name}`;
  // First, so a new key goes into the agent.
  await agentUnit();
  await key(path);
  await knownHosts();
  await config(path);
}
