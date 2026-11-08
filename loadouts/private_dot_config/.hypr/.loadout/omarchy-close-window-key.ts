#!/usr/bin/env bun
// SUPER+Q closes the window, and whatever key Omarchy uses for that stops
// doing it. Omarchy's key isn't assumed (SUPER+W today, in default/hypr/
// bindings/tiling.lua): hypr-option.lua evaluates Omarchy's defaults alone
// (hypr-omarchy-defaults.lua) and lists the keys bound to the close action.
// The block in ~/.config/hypr/bindings.lua, Omarchy's personal-bindings
// file, unbinds those keys and binds SUPER+Q — hl.unbind first, as Omarchy's
// comments say (two binds on one key would both fire). Install rewrites the
// block between its markers, so it follows Omarchy if it moves the action.
// Those keys are only unbound, never given anything else. The check
// evaluates the whole config, not the file's text; install confirms it in
// the running Hyprland when there is one — by description, since with a Lua
// config hyprctl binds shows a function reference, never the action.
// Modes: `check` / `install` (default).
import { main } from "#loadout";
import { BINDINGS, OMARCHY_DEFAULTS, binds, liveInstance, probe, reload, sameKey, writeBlock } from "#hypr";

const KEY = "SUPER + Q";
const ACTION = "<window.close>";
const NAME = "omarchy-close-window-key";

const keysFor = (answer: string) => (answer === "nil" ? [] : answer.split("\n"));

/** The keys Omarchy's own defaults bind to the close action, other than KEY, as the defaults wrote them. */
const omarchyKeys = async () => keysFor(await probe(`action:${ACTION}`, OMARCHY_DEFAULTS)).filter((k) => !sameKey(k, KEY));

/** KEY runs exactly the close action, and none of Omarchy's keys still does. */
async function inPlace() {
  const defaults = await omarchyKeys();
  if ((await probe(`bind:${KEY}`)) !== ACTION) return false;
  const closing = keysFor(await probe(`action:${ACTION}`));
  return !defaults.some((d) => closing.some((c) => sameKey(c, d)));
}

async function install() {
  const keys = await omarchyKeys();
  await writeBlock(BINDINGS, NAME, [
    "-- SUPER+Q closes the window instead of Omarchy's key for it",
    "-- (loadouts/private_dot_config/.hypr/.loadout/omarchy-close-window-key.ts rewrites this block).",
    ...keys.map((k) => `hl.unbind("${k}")`),
    `hl.unbind("${KEY}")`,
    `o.bind("${KEY}", "Close window", hl.dsp.window.close())`,
  ]);
  if (!(await inPlace())) {
    throw new Error(`${KEY} doesn't close windows alone after ${BINDINGS}: something loaded later binds it or one of Omarchy's close keys`);
  }
  const sig = await liveInstance();
  if (!sig) return console.log("Hyprland isn't reachable from here; the keys change at the next login.");
  await reload(sig);
  // Every "Close window" binding in the running Hyprland: just KEY (modmask 64 = SUPER alone).
  const live = (await binds(sig)).filter((b) => b.description === "Close window").map((b) => `${b.modmask} ${b.key}`).join("|");
  if (live !== "64 Q") throw new Error(`the running Hyprland's Close window bindings are '${live}', not '64 Q'`);
}

await main(inPlace, install);
