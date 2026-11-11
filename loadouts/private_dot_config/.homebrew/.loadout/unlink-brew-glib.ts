#!/usr/bin/env bun
// Linux: brew's glib (ffmpeg, scrcpy and SDL pull it in) unlinked. Linked, its
// gsettings, gio and gdbus sit in brew's bin, ahead of the system's on PATH,
// and brew's gsettings has no dconf backend: it writes to its own keyfile, so
// `omarchy theme set` run from a terminal never tells GTK or the desktop
// portal (kitty follows that) the theme went light or dark. Its dependents
// load it from brew's opt/, so they keep working unlinked; brew upgrade keeps
// an unlinked keg unlinked. Its build-only tools (gdbus-codegen,
// glib-mkenums…) leave PATH too: nothing here builds from source.
// Modes: `check` / `install` (default).
import { accessSync, constants, existsSync } from "node:fs";
import { brew, brewPrefix, main } from "#loadout";

const prefix = await brewPrefix();

/** Without brew there's nothing to unlink. */
const hasBrew = () => {
  try {
    accessSync(`${prefix}/bin/brew`, constants.X_OK);
    return true;
  } catch {
    return false;
  }
};

const linked = () => existsSync(`${prefix}/bin/gsettings`);

function unlinked() {
  if (!hasBrew() || !linked()) return true;
  console.log("brew's glib is linked: its gsettings shadows the system's");
  return false;
}

async function install() {
  if (!hasBrew() || !linked()) return;
  await brew("unlink", "glib");
  if (linked()) throw new Error(`${prefix}/bin/gsettings is still there after brew unlink glib`);
}

await main(unlinked, install);
