#!/usr/bin/env bun
// App and scratchpad hotkeys on Hyper, like Raycast's, with
// github.com/josemiguelo/omarchy-harpoon: an Omarchy shell plugin
// (josemiguelo.harpoon, the card naming the workspace you land on) that
// omarchy-plugins installs, and its engine, hypr/harpoon.lua, linked as
// ~/.config/hypr/harpoon.lua so Hyprland's Lua loads it as hypr.harpoon and
// `omarchy plugin update` updates it. omarchy-harpoon/bindings.lua is the apps
// and keys, kept as a block in ~/.config/hypr/bindings.lua, Omarchy's
// personal-bindings file, with Omarchy's scratchpad moved from SUPER+S to
// Hyper+Escape. Hyper is SUPER+CTRL+ALT+SHIFT, which the keyboard sends from
// one key (Keychron Launcher); Omarchy binds nothing on it. The check wants
// the link, the block as the repo has it and the plugin enabled, and has
// hypr-option.lua evaluate the whole config: each key runs exactly one
// binding, Hyper+Escape the scratchpad and SUPER+S nothing. Install rewrites
// the block between its markers and confirms the keys in the running Hyprland
// when there is one — by description, since with a Lua config hyprctl binds
// shows a function reference, never the action.
// Modes: `check` / `install` (default).
import { lstat, mkdir, readlink, symlink, unlink } from "node:fs/promises";
import { $, main } from "#loadout";
import { BINDINGS, HOME, binds, block, blockIn, liveInstance, noConfigErrors, probe, reload, writeBlock } from "#hypr";

const NAME = "omarchy-harpoon";
const SRC = `${import.meta.dir}/omarchy-harpoon/bindings.lua`;
const ENGINE = `${HOME}/.config/hypr/harpoon.lua`;
const HYPER = "SUPER + CTRL + ALT + SHIFT";
const MASK = 77; // SUPER 64 + CTRL 4 + ALT 8 + SHIFT 1
const PLUGIN = "josemiguelo.harpoon";
const TARGET = `${HOME}/.config/omarchy/plugins/${PLUGIN}/hypr/harpoon.lua`;

async function linked() {
  try {
    return (await lstat(ENGINE)).isSymbolicLink() && (await readlink(ENGINE)) === TARGET && (await Bun.file(TARGET).exists());
  } catch {
    return false;
  }
}

async function pluginEnabled() {
  const plugins = await $`omarchy plugin list --json`.quiet().nothrow();
  try {
    return (JSON.parse(plugins.stdout.toString()) as { id: string; enabled: boolean }[]).some((p) => p.id === PLUGIN && p.enabled);
  } catch {
    return false;
  }
}

const body = async () => (await Bun.file(SRC).text()).replace(/\n$/, "").split("\n");

/** The letters bindings.lua binds on Hyper. */
const keys = async () => [...(await Bun.file(SRC).text()).matchAll(/^harpoon\.bind\(hyper \.\. "([A-Z0-9]*)"/gm)].map((m) => m[1]);

/** Each key runs exactly the one harpoon binding (a Lua function), and the scratchpad is on Hyper+Escape alone. */
async function bound() {
  for (const k of await keys()) if ((await probe(`bind:${HYPER} + ${k}`)) !== "<dispatcher>") return false;
  return (await probe(`bind:${HYPER} + ESCAPE`)) === "<workspace.toggle_special>" && (await probe("bind:SUPER + S")) === "nil";
}

const inPlace = async () =>
  (await linked()) && (await blockIn(BINDINGS, NAME)).join("\n") === block(NAME, await body()).join("\n") && (await bound()) && (await pluginEnabled());

async function install() {
  if (!((await Bun.file(TARGET).exists()) && (await pluginEnabled()))) throw new Error(`${PLUGIN} isn't installed and enabled: add it to omarchy-plugins`);
  await mkdir(`${HOME}/.config/hypr`, { recursive: true });
  await unlink(ENGINE).catch(() => {});
  await symlink(TARGET, ENGINE);
  await writeBlock(BINDINGS, NAME, await body());
  if (!(await inPlace())) throw new Error(`the Hyper keys don't each run one harpoon binding after ${BINDINGS}: something loaded later binds them`);
  const sig = await liveInstance();
  if (!sig) return console.log("Hyprland isn't reachable from here; the keys work at the next login.");
  await reload(sig);
  await noConfigErrors(sig);
  const live = await binds(sig);
  for (const k of [...(await keys()), "ESCAPE"]) {
    const got = live.filter((b) => b.modmask === MASK && b.key === k).map((b) => b.description);
    if (got.length !== 1) throw new Error(`the running Hyprland binds Hyper+${k} to '${got.join("|")}', not one harpoon key`);
  }
  // modmask 64: SUPER alone.
  if (live.some((b) => b.modmask === 64 && b.key === "S")) throw new Error("the running Hyprland still binds SUPER+S");
}

await main(inPlace, install);
