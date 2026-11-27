// The vault, brought by Obsidian Sync, before anything configures it
// (obsidian-copilot). Obsidian keeps its account and Sync state in Chromium's
// storage, which no script can read, so this waits for what a finished sync
// leaves on disk instead:
//
// check: the vault registered in Obsidian's obsidian.json, with its config
// folder (.obsidian) and a note, and this script's marker that it saw the
// vault settle once (kept in the state dir, not in the vault, which Sync would
// copy to other devices).
// install: opens Obsidian, says what to do, and waits on purpose, as
// onepassword-signin does for the app's switch: for the vault as check sees it,
// then for its files to stop changing for OBSIDIAN_QUIET seconds (default 30),
// the closest thing to "Sync is done" a script can see; then writes the
// marker. A sync that pauses longer goes on afterwards, harmlessly (Copilot
// needs only the config; Miyo indexes notes as they come). Each wait gives up
// after OBSIDIAN_WAIT seconds (default 900; 0 doesn't wait).
import { mkdirSync, readdirSync, statSync } from "node:fs";
import { dirname } from "node:path";
import { fail, read } from "loadout/script";
import { openObsidian, seconds, vaultPath, waitForUser } from "#obsidian";
import type { Options } from "./vault.rules.ts";

const WAIT = seconds("OBSIDIAN_WAIT", 900);
const QUIET = seconds("OBSIDIAN_QUIET", 30);
const OBSIDIAN_JSON = `${process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`}/obsidian/obsidian.json`;
const SYNCED = `${process.env.XDG_STATE_HOME || `${process.env.HOME}/.local/state`}/loadout/obsidian-vault-synced`;

const isDir = (path: string) => statSync(path, { throwIfNoEntry: false })?.isDirectory() ?? false;

/** Is it one of the vaults Obsidian knows? */
async function registered(vault: string) {
  try {
    const { vaults } = JSON.parse((await read(OBSIDIAN_JSON)) || "{}") as { vaults?: Record<string, { path?: string }> };
    return Object.values(vaults ?? {}).some((v) => v.path && vaultPath(v.path) === vault);
  } catch {
    return false;
  }
}

/**
 * Every file under the vault, as a count and total size (what changes while
 * Sync downloads), and its notes. Sync moves files while this walks, so a
 * walk that trips over one is simply tried again.
 */
async function footprint(vault: string) {
  for (let attempt = 0; ; attempt++) {
    try {
      let files = 0;
      let bytes = 0;
      let notes = 0;
      for (const entry of readdirSync(vault, { recursive: true, withFileTypes: true })) {
        if (!entry.isFile()) continue;
        files++;
        bytes += statSync(`${entry.parentPath}/${entry.name}`, { throwIfNoEntry: false })?.size ?? 0;
        if (entry.name.endsWith(".md") && !entry.parentPath.includes("/.obsidian")) notes++;
      }
      return { files, bytes, notes };
    } catch (error) {
      if (attempt >= 5) throw error;
      await Bun.sleep(500);
    }
  }
}

/** The vault as check wants it, short of the marker. */
async function present(vault: string) {
  return (await registered(vault)) && isDir(`${vault}/.obsidian`) && (await footprint(vault)).notes > 0;
}

export async function check(options: Options) {
  const vault = vaultPath(options.vault);
  return (await read(SYNCED)).trim() === vault && (await present(vault));
}

export async function install(options: Options) {
  const vault = vaultPath(options.vault);
  if (!(await present(vault))) openObsidian();
  await waitForUser("obsidian-vault", () => present(vault), {
    wait: WAIT,
    instructions: `Waiting for the Obsidian vault (up to {wait}). In Obsidian:
      1. Settings → Sync → log in to your Obsidian account
      2. Connect the remote vault to ${vault}
    This goes on by itself once it has synced.`,
  });

  // Sync is done, as far as the disk can tell, once nothing has changed for QUIET seconds.
  console.warn(`obsidian-vault: ${vault} is there; waiting for Sync to settle (${QUIET}s without changes)…`);
  const deadline = Date.now() + WAIT * 1000;
  let seen = await footprint(vault);
  let since = Date.now();
  while (Date.now() - since < QUIET * 1000) {
    if (Date.now() >= deadline) fail(`obsidian-vault: Sync didn't settle in ${WAIT}s; run this again once it has`);
    await Bun.sleep(2000);
    const now = await footprint(vault);
    if (now.files !== seen.files || now.bytes !== seen.bytes) {
      seen = now;
      since = Date.now();
    }
  }
  mkdirSync(dirname(SYNCED), { recursive: true });
  await Bun.write(SYNCED, `${vault}\n`);
  console.warn(`obsidian-vault: synced (${seen.notes} notes, ${seen.files} files)`);
}
