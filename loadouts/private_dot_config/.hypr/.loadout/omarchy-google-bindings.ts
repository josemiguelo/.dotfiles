#!/usr/bin/env bun
// Omarchy's email and calendar keys open HEY (default/hypr/bindings/
// applications.lua). This rebinds them to Gmail and Google Calendar in
// ~/.config/hypr/bindings.lua, Omarchy's personal-bindings file, the way its
// own comments say: hl.unbind the key, then bind it again (two binds on one
// key would both fire). The check doesn't read the file's text:
// hypr-option.lua evaluates the whole Lua config and reports what each key
// runs. Install confirms it in the running Hyprland when there is one — by
// description: with a Lua config, hyprctl binds shows every binding as a Lua
// function reference, never the command, so each key's one binding must carry
// the description given here.
// Modes: `check` / `install` (default).
import { mkdir, chmod, stat } from "node:fs/promises";
import { main, read } from "#loadout";
import { BINDINGS, binds, liveInstance, probe, reload } from "#hypr";

const BEGIN = "-- >>> Managed by loadout (omarchy-google-bindings)";
const END = "-- <<< Managed by loadout (omarchy-google-bindings)";
// The block an earlier version appended, unmarked at its end: from its
// comment through its last bind. Install replaces it like its own.
const LEGACY = "-- Managed by loadout (omarchy-google-bindings)";
const LEGACY_LAST = 'o.bind("SUPER + SHIFT + C"';

const MAIL = "https://mail.google.com/";
const COMPOSE = "https://mail.google.com/mail/?view=cm&fs=1";
const CALENDAR = "https://calendar.google.com/";

/** What o.bind makes of { webapp = url }. */
const webapp = (url: string) => `omarchy-launch-webapp '${url}'`;

const KEYS: [key: string, description: string, url: string, mask: number, letter: string][] = [
  ["SUPER + SHIFT + E", "Gmail", MAIL, 65, "E"], // modmask: SUPER 64 + SHIFT 1
  ["SUPER + SHIFT + ALT + E", "New Gmail message", COMPOSE, 73, "E"], // + ALT 8
  ["SUPER + SHIFT + C", "Google Calendar", CALENDAR, 65, "C"],
];

const block = () => [
  BEGIN,
  "-- Gmail and Google Calendar in HEY's place",
  "-- (loadouts/private_dot_config/.hypr/.loadout/omarchy-google-bindings.ts).",
  ...KEYS.flatMap(([key, description, url]) => [`hl.unbind("${key}")`, `o.bind("${key}", "${description}", { webapp = "${url}" })`]),
  END,
];

/**
 * BINDINGS without any block of ours (marked, or the old unmarked one), then
 * the current block; written whole, so it's never half there. Blank lines are
 * held until a kept line follows, so the ones left at the end don't pile up
 * rewrite after rewrite. The old block also ends at its first line that isn't
 * a comment, an unbind or a bind (kept): one edited by hand never swallows the rest.
 */
async function writeBlock() {
  let kept = "";
  let blanks = "";
  let skip = 0;
  for (const line of (await read(BINDINGS)).replace(/\n$/, "").split("\n")) {
    if (line === BEGIN) skip = 1;
    if (line.startsWith(LEGACY)) skip = 2;
    if (skip === 2 && !/^(--|hl\.|o\.)/.test(line)) skip = 0;
    if (!skip && /^\s*$/.test(line)) { blanks += "\n"; continue; }
    if (!skip) { kept += blanks + line + "\n"; blanks = ""; }
    if (skip === 1 && line === END) skip = 0;
    if (skip === 2 && line.startsWith(LEGACY_LAST)) skip = 0;
  }
  const mode = await stat(BINDINGS).then((s) => s.mode & 0o777, () => 0o644);
  await mkdir(`${process.env.HOME}/.config/hypr`, { recursive: true });
  await Bun.write(BINDINGS, kept + "\n" + block().join("\n") + "\n");
  await chmod(BINDINGS, mode);
}

/** Every key runs exactly the one command. */
async function bound() {
  for (const [key, , url] of KEYS) if ((await probe(`bind:${key}`)) !== webapp(url)) return false;
  return true;
}

async function install() {
  await probe("bind:SUPER + SHIFT + E");
  // Rewritten whenever a key is off: an edited URL replaces the block, not a second one after it.
  if (!(await bound())) await writeBlock();
  if (!(await bound())) throw new Error(`the email/calendar keys still don't open Google after ${BINDINGS}: something loaded later binds them`);
  const sig = await liveInstance();
  if (!sig) return console.log("Hyprland isn't reachable from here; the keys change at the next login.");
  await reload(sig);
  const live = await binds(sig);
  for (const [, description, , mask, letter] of KEYS) {
    const got = live.filter((b) => b.modmask === mask && b.key === letter).map((b) => b.description).join("|");
    if (got !== description) throw new Error(`the running Hyprland binds key ${letter} (modmask ${mask}) to '${got}', not '${description}'`);
  }
}

await main(bound, install);
