#!/usr/bin/env bun
// Omarchy sets up every coding agent it offers, used or not. This removes
// what it set up for the agents the machine doesn't name:
//
// - the launcher it writes into ~/.local/bin (install/user/mise.sh via
//   omarchy-mise-install): a script that runs `mise use -g <tool>` on first
//   use. Like omarchy-remove-preinstalls decides what is Omarchy's: a regular
//   file (not a symlink — Cursor's own installer links cursor-agent) carrying
//   the `mise use -g` line. Anything else at those paths is left alone (since
//   Omarchy 4.0.5, hermes is Hermes Desktop's own command, not a launcher).
// - the config folder it seeds into ~/.config from $OMARCHY_PATH/config
//   (only opencode has one): removed only while the agent isn't installed
//   (on PATH other than as that launcher) and every file in it is still
//   Omarchy's copy, so a config of your own stays. Left there, it makes
//   workmux setup take the agent as installed and fail on `<agent> --version`.
//
// Omarchy re-provisioning (or omarchy-reinstall-configs) writes them again, so
// the check catches a return.
// usage: omarchy-agents-prune.ts [check] <agent-to-keep>...
import { lstatSync, readdirSync, statSync } from "node:fs";
import { rm } from "node:fs/promises";
import { main, read } from "#loadout";

const HOME = process.env.HOME!;
const BIN = `${HOME}/.local/bin`;
const CONFIG = process.env.XDG_CONFIG_HOME || `${HOME}/.config`;
const OMARCHY_CONFIG = `${process.env.OMARCHY_PATH || "/usr/share/omarchy"}/config`;

/** Agents whose config folder Omarchy seeds, by the folder's name. */
const AGENT_CONFIGS = ["opencode"];

const isDir = (path: string) => statSync(path, { throwIfNoEntry: false })?.isDirectory() ?? false;

/** A regular file, not a link, that runs `mise use -g` on first use. */
async function omarchyLauncher(path: string) {
  if (!lstatSync(path, { throwIfNoEntry: false })?.isFile()) return false;
  return /^mise use -g /m.test(await read(path));
}

/** On PATH as itself, not as Omarchy's launcher for it. */
async function installed(name: string) {
  const command = Bun.which(name);
  return command !== null && !(await omarchyLauncher(command));
}

/** Every file in ~/.config/<agent> is the same as in Omarchy's copy. */
async function omarchyConfig(name: string) {
  const mine = `${CONFIG}/${name}`;
  const theirs = `${OMARCHY_CONFIG}/${name}`;
  if (!isDir(mine) || !isDir(theirs)) return false;
  for (const file of readdirSync(mine, { recursive: true }) as string[]) {
    if (isDir(`${mine}/${file}`)) continue;
    const ours = Bun.file(`${mine}/${file}`);
    const stock = Bun.file(`${theirs}/${file}`);
    if (!(await stock.exists()) || !Buffer.from(await ours.bytes()).equals(await stock.bytes())) return false;
  }
  return true;
}

/** What Omarchy set up for agents not in keep, by full path. */
async function extra(keep: string[]) {
  const found: string[] = [];
  let names: string[] = [];
  try {
    names = readdirSync(BIN).sort();
  } catch {}
  for (const name of names) {
    if (!keep.includes(name) && (await omarchyLauncher(`${BIN}/${name}`))) found.push(`${BIN}/${name}`);
  }
  for (const name of AGENT_CONFIGS) {
    if (keep.includes(name) || (await installed(name))) continue;
    if (await omarchyConfig(name)) found.push(`${CONFIG}/${name}`);
  }
  return found;
}

async function install(...keep: string[]) {
  for (const path of await extra(keep)) {
    await rm(path, { recursive: true, force: true });
    console.log(`removed ${path}`);
  }
  const left = await extra(keep);
  if (left.length) throw new Error(`Omarchy agent files still present: ${left.join(" ")}`);
}

await main(async (...keep) => (await extra(keep)).length === 0, install);
