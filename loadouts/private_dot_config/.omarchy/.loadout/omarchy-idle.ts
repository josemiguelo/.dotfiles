#!/usr/bin/env bun
// How long the session sits idle before the shell locks it (and turns the
// display off, which also ends the screensaver), from the machine's opt-in
// ("omarchy-idle 1000"). It's Omarchy's own setting, idle.lock in
// ~/.config/omarchy/shell.json, in seconds; idle.screensaver (when the
// screensaver starts) is left as it is. Only the key is set, the rest of the
// file is kept; a missing or empty file starts from Omarchy's defaults, as
// Omarchy's own editing does (omarchy-shell-config), since the shell reads a
// user file in their place, not over them. The shell is told to reload.
// usage: omarchy-idle.ts [check] <lock-seconds>
import { $, fail, main, ok, read } from "loadout/script";
import { SHELL_JSON, readJson, replaceFile, shellReady } from "#omarchy";

const DEFAULTS = `${process.env.OMARCHY_PATH || "/usr/share/omarchy"}/config/omarchy/shell.json`;

function lockSeconds(args: string[]) {
  if (args.length === 0) fail("usage: omarchy-idle.ts [check] <lock-seconds>");
  if (!/^[0-9]+$/.test(args[0])) fail("lock-seconds must be a whole number");
  return Number(args[0]);
}

const setAlready = async (lock: number) => (await readJson(SHELL_JSON))?.idle?.lock === lock;

async function install(...args: string[]) {
  const lock = lockSeconds(args);
  if (!(await setAlready(lock))) {
    const from = (await read(SHELL_JSON)).trim() ? SHELL_JSON : DEFAULTS;
    const shell = JSON.parse(await read(from));
    shell.version = 1;
    shell.idle = { ...(shell.idle ?? {}), lock };
    await replaceFile(SHELL_JSON, JSON.stringify(shell, null, 2) + "\n");
    try {
      await shellReady();
      await ok($`omarchy-shell shell reloadConfig`);
    } catch {}
  }
  if (!(await setAlready(lock))) throw new Error(`${SHELL_JSON}'s idle.lock isn't ${lock} after install`);
}

const alreadySet = (...args: string[]) => setAlready(lockSeconds(args));

await main(alreadySet, install);
