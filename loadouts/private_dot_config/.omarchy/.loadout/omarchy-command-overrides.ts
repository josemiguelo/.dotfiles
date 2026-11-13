#!/usr/bin/env bun
// A place for local replacements of Omarchy commands: the directory
// ~/.local/share/omarchy-overrides/bin, first on the PATH of everything
// Hyprland starts. Omarchy puts $OMARCHY_PATH/bin at the front of that PATH
// (default/hypr/envs.lua), ahead of any system directory, so a block in
// ~/.config/hypr/hyprland.lua — loaded after envs.lua — puts this directory in
// front of it the same way, removing it first so reloads don't stack it. The
// fixes that need a replacement (omarchy-keyboard-backlight-guard,
// t2-gmux-backlight) each put or remove their own wrapper there.
// Install reloads Hyprland and restarts the shell, so the shell runs with the
// PATH — only when the block changed or the shell doesn't have it yet. The
// check reads the PATH the evaluated config produces (hypr-option.lua
// env:PATH) and the running shell's.
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import { $, main, read } from "loadout/script";
import { HOME, block, blockIn, liveInstance, probe, reload, writeBlock } from "#hypr";
import { OVERRIDES_DIR, shellPath } from "#omarchy";

const CONF = `${HOME}/.config/hypr/hyprland.lua`;
const NAME = "omarchy-command-overrides";
/** The block's earlier owner, moved here. */
const OLD_NAME = "omarchy-keyboard-backlight-guard";

const body = [
  "-- Local replacements of Omarchy commands first on the PATH of everything",
  "-- Hyprland starts, ahead of $OMARCHY_PATH/bin that default/hypr/envs.lua puts",
  "-- first — removed before being added again, so reloads don't stack it.",
  'local overrides = os.getenv("HOME") .. "/.local/share/omarchy-overrides/bin"',
  "local path = { overrides }",
  'for entry in (os.getenv("PATH") or ""):gmatch("[^:]+") do',
  "  if entry ~= overrides then table.insert(path, entry) end",
  "end",
  'hl.env("PATH", table.concat(path, ":"))',
];

const firstOn = (path: string) => path.split(":")[0] === OVERRIDES_DIR;

/** The block as written, and no block of its earlier owner. */
const written = async () =>
  (await blockIn(CONF, NAME)).join("\n") === block(NAME, body).join("\n") && (await blockIn(CONF, OLD_NAME)).length === 0;

async function inPlace() {
  if (!existsSync(OVERRIDES_DIR) || !(await written())) return false;
  if (!firstOn(await probe("env:PATH"))) return false;
  const live = await shellPath();
  return !live || firstOn(live);
}

async function install() {
  await mkdir(OVERRIDES_DIR, { recursive: true });
  if (!(await written())) await writeBlock(CONF, NAME, body, [OLD_NAME]);
  const live = await shellPath();
  if (!live || !firstOn(live)) {
    const sig = await liveInstance();
    if (!sig) return console.log("Hyprland isn't reachable from here; applies at the next login.");
    await reload(sig);
    await $`omarchy-restart-shell`.env({ ...process.env, HYPRLAND_INSTANCE_SIGNATURE: sig }).quiet();
  }
  if (!(await inPlace())) throw new Error(`${OVERRIDES_DIR} isn't first on the shell's PATH after install`);
}

await main(inPlace, install);
