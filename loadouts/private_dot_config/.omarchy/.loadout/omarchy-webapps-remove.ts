#!/usr/bin/env bun
// Removes the named Omarchy web apps (launcher + icon) with Omarchy's own
// omarchy-webapp-remove. Omarchy copies its bundled web apps back whenever it
// re-provisions applications (omarchy-refresh-applications: a re-provision,
// restoring preinstalls, some migrations), so the check catches a return.
// Names are the launchers' file names (HEY for HEY.desktop); loadout splits
// arguments on spaces, so a name with one can't be passed.
// usage: omarchy-webapps-remove.ts [check] <name>...
import { existsSync } from "node:fs";
import { $, fail, main } from "#loadout";

const DIR = `${process.env.HOME}/.local/share/applications`;

function names(args: string[]) {
  if (args.length === 0) fail("usage: omarchy-webapps-remove.ts [check] <name>...");
  return args;
}

const stillThere = (args: string[]) => names(args).filter((name) => existsSync(`${DIR}/${name}.desktop`));

async function install(...args: string[]) {
  for (const name of stillThere(args)) {
    await $`omarchy-webapp-remove ${name}`.env({ ...process.env, OMARCHY_REMOVE_NOTIFY: "false" });
  }
  const left = stillThere(args);
  if (left.length) throw new Error(`still installed after removal: ${left.join(" ")}`);
}

await main((...args) => stillThere(args).length === 0, install);
