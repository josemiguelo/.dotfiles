// Removes the named Omarchy web apps (launcher + icon) with Omarchy's own
// omarchy-webapp-remove. Omarchy copies its bundled web apps back whenever it
// re-provisions applications (omarchy-refresh-applications: a re-provision,
// restoring preinstalls, some migrations), so the check catches a return.
// Names are the launchers' file names (HEY for HEY.desktop); loadout splits
// arguments on spaces, so a name with one can't be passed.
import { existsSync } from "node:fs";
import { $ } from "loadout/script";
import type { Options } from "./omarchy-webapps-remove.rules.ts";

const DIR = `${process.env.HOME}/.local/share/applications`;

const stillThere = (names: string[]) => names.filter((name) => existsSync(`${DIR}/${name}.desktop`));

export async function install({ names }: Options) {
  for (const name of stillThere(names)) {
    await $`omarchy-webapp-remove ${name}`.env({ ...process.env, OMARCHY_REMOVE_NOTIFY: "false" });
  }
  const left = stillThere(names);
  if (left.length) throw new Error(`still installed after removal: ${left.join(" ")}`);
}

export const check = ({ names }: Options) => stillThere(names).length === 0;
