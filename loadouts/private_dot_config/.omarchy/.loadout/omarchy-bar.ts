#!/usr/bin/env bun
// The Omarchy bar itself, from the machine's opt-in, as what differs from a
// fresh install: its position and thickness, and optionally its background,
// its icon size and the stock widgets turned off, one key=value per argument
// ("omarchy-bar position=top size=24 background=glassy off=omarchy.workspaces";
// off= repeats). Where widgets sit and their settings are
// omarchy-bar-widgets'.
//
// The position and the background (opaque, glassy or none; Omarchy's default
// is opaque) are Omarchy's own settings (~/.config/omarchy/shell.json,
// bar.position and bar.background), set with `omarchy bar position` and
// `omarchy bar background`; a background the opt-in leaves out is left as it
// is. A glassy bar is see-through and Hyprland blurs what's behind it, while
// the bar-glassy toggle (~/.local/state/omarchy/toggles/hypr/bar-glassy.lua,
// a copy of Omarchy's default/hypr/toggles/bar-glassy.lua) is in place:
// `omarchy bar background` puts it there for glassy and removes it otherwise,
// so the check asks for both. The thickness is size-horizontal (top and
// bottom bars; size-vertical for left and right ones; Omarchy's default is
// 26) at font base-size 12, scaled with the font like Omarchy's; it lives in
// a block in ~/.config/omarchy/shell.toml, the machine-level file whose keys
// win over the theme's and which the shell reloads live. The icon size is
// icon-size, the size every bar icon is drawn at, glyph or SVG (Omarchy's
// default is 12), with icon-canvas raised to match: the icon is drawn at the
// smaller of the two. Both sit in the same block; left out, Omarchy's own
// sizes apply. `omarchy display text size` edits [font] there and leaves the
// rest. A [bar] table outside the block would make the file invalid TOML, so
// install refuses one. The bar's text follows the shell's [font] base-size.
//
// A stock widget turned off (omarchy.workspaces, when a plugin draws the
// workspaces) is disabled with `omarchy plugin disable`, which takes it off
// the bar.
// usage: omarchy-bar.ts [check] position=<top|bottom|left|right> size=<n> [background=<opaque|glassy|none>] [icon-size=<n>] [off=<widget-id>]...
import { existsSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { $, fail, main, read } from "loadout/script";
import { HOME } from "#hypr";
import { SHELL_JSON, readJson, shellReady, widgetEnabled } from "#omarchy";

const USAGE =
  "usage: omarchy-bar.ts [check] position=<top|bottom|left|right> size=<n> [background=<opaque|glassy|none>] [icon-size=<n>] [off=<widget-id>]...";
const TOML = `${HOME}/.config/omarchy/shell.toml`;
const GLASS = `${process.env.XDG_STATE_HOME || `${HOME}/.local/state`}/omarchy/toggles/hypr/bar-glassy.lua`;
const BEGIN = "# >>> Managed by loadout (omarchy-bar)";
const END = "# <<< Managed by loadout (omarchy-bar)";

type Bar = { position: string; size: string; background: string; iconSize: string; off: string[] };

function parse(args: string[]): Bar {
  const bar: Bar = { position: "", size: "", background: "", iconSize: "", off: [] };
  for (const arg of args) {
    if (!arg.includes("=")) fail(`${arg}: not a key=value this script knows\n${USAGE}`);
    const [key, value] = [arg.slice(0, arg.indexOf("=")), arg.slice(arg.indexOf("=") + 1)];
    if (key === "position") bar.position = value;
    else if (key === "size") bar.size = value;
    else if (key === "background") bar.background = value;
    else if (key === "icon-size") bar.iconSize = value;
    else if (key === "off" && value) bar.off.push(value);
    else fail(`${arg}: not a key=value this script knows\n${USAGE}`);
  }
  if (!["top", "bottom", "left", "right"].includes(bar.position)) fail(`position must be top, bottom, left or right\n${USAGE}`);
  if (!/^[0-9]+$/.test(bar.size)) fail("size must be a whole number");
  if (!["", "opaque", "glassy", "none"].includes(bar.background)) fail("background must be opaque, glassy or none");
  if (!/^[0-9]*$/.test(bar.iconSize)) fail("icon-size must be a whole number");
  return bar;
}

function block(bar: Bar) {
  const key = bar.position === "top" || bar.position === "bottom" ? "size-horizontal" : "size-vertical";
  return [
    BEGIN,
    "# The bar's thickness at font base-size 12 and its icon size (loadouts/private_dot_config/.omarchy/.loadout/omarchy-bar.ts).",
    "[bar]",
    `${key} = ${bar.size}`,
    ...(bar.iconSize ? [`icon-size = ${bar.iconSize}`, `icon-canvas = ${bar.iconSize}`] : []),
    END,
  ];
}

/** shell.toml split into the block (markers included) and the rest, as lines. */
async function toml() {
  const text = (await read(TOML)).replace(/\n+$/, "");
  const ours: string[] = [];
  const rest: string[] = [];
  let inside = false;
  for (const line of text ? text.split("\n") : []) {
    if (line === BEGIN) inside = true;
    (inside ? ours : rest).push(line);
    if (line === END) inside = false;
  }
  return { ours, rest };
}

const ownBarTable = (rest: string[]) => rest.some((l) => /^\s*\[bar\]/.test(l));

async function positioned(bar: Bar) {
  const shell = await readJson(SHELL_JSON);
  return shell !== null && (shell.bar?.position ?? "top") === bar.position;
}

/** No background named, or it's the one the bar has, with Hyprland's blur behind it exactly when it's glassy. */
async function backed(bar: Bar) {
  if (!bar.background) return true;
  const shell = await readJson(SHELL_JSON);
  if (!shell || (shell.bar?.background ?? "opaque") !== bar.background) return false;
  return existsSync(GLASS) === (bar.background === "glassy");
}

async function sized(bar: Bar) {
  const { ours, rest } = await toml();
  return ours.join("\n") === block(bar).join("\n") && !ownBarTable(rest);
}

/** Every stock widget named off is disabled. */
async function off(bar: Bar) {
  for (const id of bar.off) if (await widgetEnabled(id)) return false;
  return true;
}

const inPlace = async (bar: Bar) => (await positioned(bar)) && (await backed(bar)) && (await sized(bar)) && (await off(bar));

async function check(...args: string[]) {
  const bar = parse(args);
  await shellReady("check");
  return inPlace(bar);
}

async function install(...args: string[]) {
  const bar = parse(args);
  await shellReady();
  const { rest } = await toml();
  if (ownBarTable(rest)) throw new Error(`${TOML} has its own [bar] table: move its keys into the opt-in, or remove it`);
  if (!(await positioned(bar))) await $`omarchy bar position ${bar.position}`;
  if (!(await backed(bar))) await $`omarchy bar background ${bar.background}`.quiet();
  await mkdir(dirname(TOML), { recursive: true });
  const others = rest.join("\n").replace(/\n+$/, "");
  await Bun.write(TOML, (others ? others + "\n\n" : "") + block(bar).join("\n") + "\n");
  for (const id of bar.off) if (await widgetEnabled(id)) await $`omarchy plugin disable ${id}`.quiet();
  if (!(await inPlace(bar))) {
    throw new Error("the bar's position, background, thickness, icon size or stock widgets turned off aren't what the opt-in names after install");
  }
}

await main(check, install);
