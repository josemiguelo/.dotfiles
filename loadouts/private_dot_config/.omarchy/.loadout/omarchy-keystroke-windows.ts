#!/usr/bin/env bun
// Keystroke's Windows extension (every open window, grouped by workspace),
// the one Keystroke ships in its own extensions/ (since 1.5.1): turned on in
// ~/.config/omarchy/keystroke.json (providers.windows.enabled, the rest of the
// file kept), since every extension starts off. Hyper+Space
// (SUPER+CTRL+ALT+SHIFT+SPACE) opens the palette on its screen, from a block
// in ~/.config/hypr/bindings.lua. A copy under
// ~/.local/share/keystroke/extensions/ would replace the shipped one (that's
// where an author iterates on it), so the link an earlier version of this
// script made to a Keystroke checkout goes. The check reads the setting, and
// has hypr-option.lua evaluate the whole config: the key runs exactly that
// command. Install confirms the key in the running Hyprland when there is
// one, by description.
// Modes: `check` / `install` (default).
import { existsSync, lstatSync } from "node:fs";
import { rm } from "node:fs/promises";
import { main, read } from "loadout/script";
import { BINDINGS, HOME, binds, block, blockIn, liveInstance, noConfigErrors, probe, reload, writeBlock } from "#hypr";
import { pluginUpdateHint, readJson, replaceFile } from "#omarchy";

const NAME = "omarchy-keystroke-windows";
const BUNDLED = `${HOME}/.config/omarchy/plugins/evindor.keystroke/extensions/windows`;
const OLD_LINK = `${HOME}/.local/share/keystroke/extensions/windows`;
const SETTINGS = `${HOME}/.config/omarchy/keystroke.json`;
const KEY = "SUPER + CTRL + ALT + SHIFT + SPACE";
const COMMAND = `omarchy-shell shell toggle omarchy.menu '{"scope":"windows","title":"Windows"}'`;
const MASK = 77; // SUPER 64 + CTRL 4 + ALT 8 + SHIFT 1

const body = [
  "-- Hyper+Space opens Keystroke on its Windows screen",
  "-- (loadouts/private_dot_config/.omarchy/.loadout/omarchy-keystroke-windows.ts rewrites this block).",
  `hl.unbind("${KEY}")`,
  `o.bind("${KEY}", "Windows", [[${COMMAND}]])`,
];

/** Keystroke's own copy, not shadowed by a local one. */
const bundled = () => existsSync(`${BUNDLED}/extension.json`) && !lstatSync(OLD_LINK, { throwIfNoEntry: false });

const enabled = async () => (await readJson(SETTINGS))?.providers?.windows?.enabled === true;

const inPlace = async () =>
  bundled() &&
  (await enabled()) &&
  (await blockIn(BINDINGS, NAME)).join("\n") === block(NAME, body).join("\n") &&
  (await probe(`bind:${KEY}`)) === COMMAND;

async function install() {
  if (!existsSync(`${BUNDLED}/extension.json`)) {
    await pluginUpdateHint("evindor.keystroke");
    throw new Error(`no Windows extension at ${BUNDLED}: is Keystroke (evindor.keystroke, from omarchy-plugins) 1.5.1 or later installed?`);
  }
  const old = lstatSync(OLD_LINK, { throwIfNoEntry: false });
  if (old?.isSymbolicLink()) await rm(OLD_LINK);
  else if (old) throw new Error(`${OLD_LINK} would replace Keystroke's own Windows extension; move it away first`);
  // Keystroke reloads the file when it changes and refuses one without
  // "version"; the new copy replaces the old one in a single rename.
  const settings = (await read(SETTINGS)) ? JSON.parse(await read(SETTINGS)) : { version: 1 };
  settings.version ??= 1;
  settings.providers ??= {};
  settings.providers.windows ??= {};
  settings.providers.windows.enabled = true;
  await replaceFile(SETTINGS, JSON.stringify(settings, null, 2) + "\n");
  await writeBlock(BINDINGS, NAME, body);
  if (!(await inPlace())) throw new Error(`Hyper+Space doesn't run only the Windows command after ${BINDINGS}: something loaded later binds it`);
  const sig = await liveInstance();
  if (!sig) return console.log("Hyprland isn't reachable from here; the key works at the next login.");
  await reload(sig);
  await noConfigErrors(sig);
  const got = (await binds(sig)).filter((b) => b.modmask === MASK && b.key === "SPACE").map((b) => b.description).join("|");
  if (got !== "Windows") throw new Error(`the running Hyprland binds Hyper+Space to '${got}', not 'Windows'`);
}

await main(inPlace, install);
