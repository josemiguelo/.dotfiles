// The activity monitor (SUPER+CTRL+T: omarchy-launch-tui btop, window class
// org.omarchy.btop) at the machine's size instead of 875x600, the size
// Omarchy gives every window tagged floating-window (default/hypr/apps/
// system.lua), btop among them. A window rule in ~/.config/hypr/hyprland.lua,
// where Omarchy puts personal additions: it matches the tag as well as the
// class because Hyprland applies tag-matched rules after class-only ones — a
// class-only rule loses to Omarchy's, tried live. Only btop changes; the
// other floating windows keep Omarchy's size. The check doesn't read the
// file's text: hypr-option.lua evaluates the whole Lua config and lists every
// window rule that sets a size; the last floating-window one that can match
// btop must be this size. Install rewrites the block between its markers.
// A size is pixels (1400) or a share of the monitor (80%), which becomes a
// Hyprland expression — (monitor_w*0.8) — the form Omarchy's own webcam
// overlay rule uses, so it follows whatever screen the window opens on.
import { HOME, liveInstance, noConfigErrors, probe, reload, writeBlock } from "#hypr";
import type { Options, Size } from "./omarchy-activity-monitor-size.rules.ts";

const NAME = "omarchy-activity-monitor-size";
const CLASS = "org.omarchy.btop";
const TAG = "floating-window";
const CONF = `${HOME}/.config/hypr/hyprland.lua`;

/** 80% on axis w -> (monitor_w*0.8); pixels stay as they are. */
const sizeOf = (size: Size, axis: string) => (typeof size === "string" ? `(monitor_${axis}*${Number(size.slice(0, -1)) / 100})` : String(size));

/** As a Lua value: an expression is a string, pixels a number. */
const luaOf = (size: string) => (size.startsWith("(") ? `"${size}"` : size);

const sizes = ({ width, height }: Options) => ({ sw: sizeOf(width, "w"), sh: sizeOf(height, "h") });

/** The size the last floating-window rule that can match btop sets: tag rules win over class-only ones, the last one among them. */
async function effective() {
  const rules = (await probe("rules:size")).split("\n").map((l) => l.split("\t"));
  const matching = rules.filter(([cls, tag]) => tag === TAG && (!cls || new RegExp(cls).test(CLASS)));
  return matching.at(-1)?.[2] ?? "";
}

export async function check(options: Options) {
  const { sw, sh } = sizes(options);
  return (await effective()) === `${sw} ${sh}`;
}

export async function install(options: Options) {
  const { sw, sh } = sizes(options);
  await probe("rules:size");
  await writeBlock(CONF, NAME, [
    `-- The activity monitor (SUPER+CTRL+T, btop) at ${options.width} by ${options.height}, not Omarchy's`,
    "-- floating-window size. Matches the tag too: tag rules apply after",
    "-- class-only ones (loadouts/hypr/.loadout/omarchy-activity-monitor-size.ts).",
    `o.window({ class = "^(org\\\\.omarchy\\\\.btop)$", tag = "${TAG}" }, { size = { ${luaOf(sw)}, ${luaOf(sh)} } })`,
  ]);
  if (!(await check(options))) throw new Error(`btop's floating size is '${await effective()}', not '${sw} ${sh}', after ${CONF}: a later rule sets it`);
  const sig = await liveInstance();
  if (!sig) return console.log("Hyprland isn't reachable from here; applies at the next login.");
  await reload(sig);
  await noConfigErrors(sig);
  console.log("Applies to activity monitors opened from now on.");
}
