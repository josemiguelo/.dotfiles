// Hyprland settings kept in this repo: hypr-config/<file>.lua (next to this
// script) holds plain hl.config, hl.animation, hl.unbind and o.bind calls for
// ~/.config/hypr/<file>.lua, the matching personal-overrides file
// Omarchy's hyprland.lua loads after its defaults (input, looknfeel,
// bindings, …). The machine names the files. Install writes each file's
// contents into a block between markers in the Hyprland file, rewritten in
// place on every install. The check doesn't read text: hypr-option.lua
// evaluates the repo file alone to list the settings it makes (and the keys
// it binds or unbinds), then the whole Hyprland config, and every one of those must end
// up the same — a later override anywhere in the chain fails it. Install then
// reloads the running Hyprland and requires no config errors.
import { HOME, blockIn, liveInstance, noConfigErrors, probe, reload, writeBlock } from "#hypr";
import type { Options } from "./omarchy-hypr-config.rules.ts";

const SETTINGS = `${import.meta.dir}/hypr-config`;

/**
 * Blocks of scripts folded into a file here, removed when its block is
 * written: omarchy-google-bindings' keys are bindings.lua's now.
 */
const REPLACES: Record<string, string[]> = { bindings: ["omarchy-google-bindings"] };

/** Settings the named repo files make, as <path>\t<value> lines. */
async function wanted(files: string[]) {
  const lines: string[] = [];
  for (const name of files) {
    const src = `${SETTINGS}/${name}.lua`;
    if (!(await Bun.file(src).exists())) throw new Error(`no ${src}`);
    lines.push(...(await probe("leaves", src)).split("\n").filter(Boolean));
  }
  return lines;
}

/** Wanted settings the whole Hyprland config doesn't end up with. */
async function missing(files: string[]) {
  const want = await wanted(files);
  const have = new Set((await probe("leaves")).split("\n"));
  return want.filter((line) => !have.has(line));
}

/** A block a file here replaces still there: the config may end up the same, but it's stale. */
async function replacedLeft(files: string[]) {
  for (const name of files) {
    for (const old of REPLACES[name] ?? []) if ((await blockIn(`${HOME}/.config/hypr/${name}.lua`, old)).length > 0) return true;
  }
  return false;
}

export const check = async ({ files }: Options) => (await missing(files)).length === 0 && !(await replacedLeft(files));

export async function install({ files }: Options) {
  await wanted(files);
  for (const name of files) {
    const body = (await Bun.file(`${SETTINGS}/${name}.lua`).text()).replace(/\n$/, "").split("\n");
    await writeBlock(`${HOME}/.config/hypr/${name}.lua`, `omarchy-hypr-config: hypr-config/${name}.lua`, body, REPLACES[name] ?? []);
  }
  const left = await missing(files);
  if (left.length) throw new Error(`not in effect after install (is the file loaded? overridden later?):\n${left.join("\n")}`);
  const sig = await liveInstance();
  if (!sig) return console.log("Hyprland isn't reachable from here; applies at the next login.");
  await reload(sig);
  await noConfigErrors(sig);
}
