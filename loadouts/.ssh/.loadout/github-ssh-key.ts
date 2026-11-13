#!/usr/bin/env bun
// This machine's ssh key (setup-ssh's, named by the opt-in) on the GitHub
// account, titled with the machine's name, so pushes over ssh work: setup-ssh
// makes a new key on every fresh install and nothing else tells GitHub about
// it. Nothing in setup needs it (public repos are fetched over https); pushing
// does.
//
// Install logs gh in when it isn't (`gh auth login --web`: a one-time code to
// approve in the browser, the one browser step of a new machine), adds the key,
// and deletes any older key with the same title: a previous install of this
// machine. Keys with other titles are never touched. It also makes ssh gh's
// git protocol (what `gh repo clone` uses) when gh was logged in by hand with
// https before setup: the login above, which says ssh, is skipped then.
//
// gh comes from wherever the machine has it: mise's shims (Omarchy's
// conf.d/omarchy.toml installs it through mise), PATH or Homebrew's prefix
// (the gh program, macOS). The shims go first: Omarchy's ~/.local/bin/gh
// wrapper runs `mise use -g gh`, which writes gh into the dotfiles'
// config.toml. $HOME is the cwd: from the repo, mise would find the
// dotfiles' copy of its config and ask to trust it.
// The check asks GitHub over ssh whether the key authenticates. setup-ssh makes
// it without a passphrase, so ssh reads it directly; a key made earlier with
// one goes through the agent (#ssh), and while it isn't in it (no ssh since
// login) the check can't ask, and asks gh instead whether GitHub has the key.
// Install adds it to the agent (asking for such a key's passphrase) before it
// tries.
// usage: github-ssh-key.ts [check] <key-name>
import { existsSync } from "node:fs";
import { hostname } from "node:os";
import { $, main, ok } from "loadout/script";
import { brewPrefix } from "#brew";
import { onTerminal, publicKey, sshAgentUp, sshKeyLoaded } from "#ssh";

const HOME = process.env.HOME!;
const TITLE = process.env.LOADOUT_MACHINE || hostname().split(".")[0];
const MISE = process.env.MISE_DATA_DIR || `${process.env.XDG_DATA_HOME || `${HOME}/.local/share`}/mise`;

/** Is gh on the PATH set below? (Bun.which alone reads the PATH the script started with.) */
const hasGh = () => Bun.which("gh", { PATH: process.env.PATH }) !== null;

/** HOME/.ssh/name, the cwd, PATH and the agent set up for what follows. */
async function prepare(name?: string) {
  if (!name) throw new Error("usage: github-ssh-key.ts [check] <key-name>");
  process.env.PATH = `${MISE}/shims:${process.env.PATH}:${await brewPrefix()}/bin`;
  process.chdir(HOME);
  await sshAgentUp();
  return `${HOME}/.ssh/${name}`;
}

async function authenticates(key: string) {
  const ssh = await $`ssh -T -i ${key} -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1`.quiet().nothrow();
  return ssh.stdout.toString().includes("successfully authenticated");
}

/** gh's git protocol for github.com is ssh (nothing to say without gh). */
async function ghSsh() {
  if (!hasGh()) return true;
  const protocol = await $`gh config get -h github.com git_protocol`.quiet().nothrow();
  return protocol.stdout.toString().replace(/\n+$/, "") === "ssh";
}

async function onGithub(key: string) {
  const mine = await publicKey(key);
  if (mine === "" || !hasGh()) return false;
  return (await $`gh api user/keys --paginate --jq ${".[].key"}`.quiet().nothrow()).stdout.toString().includes(mine);
}

async function ready(name?: string) {
  const key = await prepare(name);
  return ((await authenticates(key)) || (!(await sshKeyLoaded(key)) && (await onGithub(key)))) && (await ghSsh());
}

/** gh logged in to github.com, allowed to manage the account's keys. */
async function login() {
  if (!hasGh()) {
    throw new Error("gh isn't installed: map the gh program for this machine (Omarchy: mise-tools installs it)");
  }
  if (!(await ok($`gh auth status -h github.com`))) {
    await onTerminal("gh", "auth", "login", "-h", "github.com", "--web", "--git-protocol", "ssh", "--skip-ssh-key", "-s", "admin:public_key");
  } else if (!(await $`gh auth status -h github.com 2>&1`.quiet().nothrow()).stdout.toString().includes("admin:public_key")) {
    await onTerminal("gh", "auth", "refresh", "-h", "github.com", "-s", "admin:public_key");
  }
}

/** Deletes the keys titled TITLE that aren't this one: a previous install of this machine. */
async function deletePrevious(mine: string) {
  const keys = await $`gh api user/keys --paginate --jq ${'.[] | "\\(.id)\\t\\(.title)\\t\\(.key)"'}`.quiet().nothrow();
  process.stderr.write(keys.stderr);
  for (const line of keys.stdout.toString().split("\n")) {
    const [id, title, ...rest] = line.split("\t");
    if (!id || title !== TITLE || rest.join("\t").includes(mine)) continue;
    await $`gh ssh-key delete ${id} --yes`;
    console.log(`deleted ${TITLE}'s previous key (id ${id})`);
  }
}

async function install(name?: string) {
  const key = await prepare(name);
  if (!existsSync(`${key}.pub`)) throw new Error(`no ${key}.pub: setup-ssh makes it`);
  if (!(await sshKeyLoaded(key))) await onTerminal("ssh-add", key);
  if (await authenticates(key)) {
    if (!(await ghSsh())) {
      await $`gh config set -h github.com git_protocol ssh`;
      console.log("gh's git protocol is ssh now");
    }
    return;
  }
  await login();
  await deletePrevious(await publicKey(key));
  if (!(await onGithub(key))) await $`gh ssh-key add ${`${key}.pub`} --title ${TITLE}`;
  if (!(await authenticates(key))) throw new Error(`GitHub still refuses ${key} over ssh`);
  if (!(await ghSsh())) await $`gh config set -h github.com git_protocol ssh`;
  console.log(`GitHub knows ${key} as "${TITLE}"`);
}

await main(ready, install);
