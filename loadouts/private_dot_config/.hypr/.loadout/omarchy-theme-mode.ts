#!/usr/bin/env bun
// The machine's dark and light Omarchy themes, named by the opt-in
// ("omarchy-theme-mode tokyo-night catppuccin-latte"; spelled as
// `omarchy theme list` prints them works too), for
// ~/.local/bin/omarchy-theme-mode-toggle, which switches to the other one.
// The pair goes into ~/.config/omarchy/theme-mode.conf; Hyper+Enter
// (SUPER+CTRL+ALT+SHIFT+RETURN) runs the toggle, from a block in
// ~/.config/hypr/bindings.lua. Each theme must exist and be of its side, as
// omarchy-theme-color reads it. The check reads the file and has
// hypr-option.lua evaluate the whole config: the key runs exactly the toggle.
// Install confirms the key in the running Hyprland when there is one, by
// description.
// usage: omarchy-theme-mode.ts [check] <dark-theme> <light-theme>
import { mkdir } from "node:fs/promises";
import { $, fail, main, out, read } from "loadout/script";
import { BINDINGS, HOME, binds, block, blockIn, liveInstance, noConfigErrors, probe, reload, writeBlock } from "#hypr";

const NAME = "omarchy-theme-mode";
const SETTINGS = `${HOME}/.config/omarchy/theme-mode.conf`;
const KEY = "SUPER + CTRL + ALT + SHIFT + RETURN";
const COMMAND = "omarchy-theme-mode-toggle";
const DESCRIPTION = "Toggle light/dark theme";
const MASK = 77; // SUPER 64 + CTRL 4 + ALT 8 + SHIFT 1

/** A theme's folder name, as omarchy-theme-set makes it from what it's given. */
const nameOf = (theme: string) => theme.toLowerCase().replaceAll(" ", "-");

function themes(args: string[]) {
  if (args.length !== 2) fail("usage: omarchy-theme-mode.ts [check] <dark-theme> <light-theme>");
  return { dark: nameOf(args[0]), light: nameOf(args[1]) };
}

const settings = ({ dark, light }: { dark: string; light: string }) =>
  [
    "# Managed by loadout (omarchy-theme-mode): the themes omarchy-theme-mode-toggle",
    "# switches between.",
    `dark=${dark}`,
    `light=${light}`,
  ].join("\n") + "\n";

const body = [
  "-- Switches between the machine's dark and light theme",
  "-- (loadouts/private_dot_config/.hypr/.loadout/omarchy-theme-mode.ts rewrites this block).",
  `hl.unbind("${KEY}")`,
  `o.bind("${KEY}", "${DESCRIPTION}", "${COMMAND}")`,
];

async function inPlace(...args: string[]) {
  const pair = themes(args);
  return (
    (await read(SETTINGS)).trimEnd() === settings(pair).trimEnd() &&
    (await blockIn(BINDINGS, NAME)).join("\n") === block(NAME, body).join("\n") &&
    (await probe(`bind:${KEY}`)) === COMMAND
  );
}

/** Fails, saying why, unless theme is installed and of mode. A user theme of a stock name overlays the stock one. */
async function ofMode(theme: string, mode: string) {
  const dirs = [`${HOME}/.config/omarchy/themes/${theme}`, `${process.env.OMARCHY_PATH || "/usr/share/omarchy"}/themes/${theme}`];
  let colors = "";
  for (const dir of dirs) if (await Bun.file(`${dir}/colors.toml`).exists()) { colors = `${dir}/colors.toml`; break; }
  if (!colors) throw new Error(`no theme '${theme}' (see omarchy theme list)`);
  const got = await out($`omarchy-theme-color --file ${colors} mode`);
  if (got !== mode) throw new Error(`theme '${theme}' is ${got}, not ${mode}`);
}

async function install(...args: string[]) {
  const pair = themes(args);
  await ofMode(pair.dark, "dark");
  await ofMode(pair.light, "light");
  await probe(`bind:${KEY}`);
  await mkdir(`${HOME}/.config/omarchy`, { recursive: true });
  await Bun.write(SETTINGS, settings(pair));
  await writeBlock(BINDINGS, NAME, body);
  if (!(await inPlace(...args))) throw new Error(`Hyper+Enter doesn't run only ${COMMAND} after ${BINDINGS}: something loaded later binds it`);
  const sig = await liveInstance();
  if (!sig) return console.log("Hyprland isn't reachable from here; the key works at the next login.");
  await reload(sig);
  await noConfigErrors(sig);
  const got = (await binds(sig)).filter((b) => b.modmask === MASK && b.key === "RETURN").map((b) => b.description).join("|");
  if (got !== DESCRIPTION) throw new Error(`the running Hyprland binds Hyper+Enter to '${got}', not '${DESCRIPTION}'`);
}

await main(inPlace, install);
