#!/usr/bin/env bun
// Brave, set up by Omarchy's own installer (`omarchy install browser brave`):
// the AUR's brave-bin, Omarchy's managed-policy directory, Omarchy's Chromium
// flags (~/.config/brave-flags.conf) and the Omarchy theme. It doesn't change
// the default browser (omarchy-default-browser-arch does that).
//
// The installer copies Omarchy's flags over brave-flags.conf, and with them
// its --load-extension line, the only one Chromium reads (the last). Whatever
// else joined that line before (Intentional's extension, which its program
// installs before this script runs; Surfingkeys' split view) would be gone,
// so the entries that aren't Omarchy's are carried onto the new line.
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { $, main, ok, read } from "#loadout";

const CONFIG = process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`;
const FLAGS = `${CONFIG}/brave-flags.conf`;
const OPTION = "--load-extension=";
// Omarchy's own extensions: the installer puts back the ones it still ships.
const OMARCHY = "/usr/share/omarchy/";

const ready = async () =>
  (await ok($`pacman -Q brave-bin`)) && existsSync(FLAGS) && existsSync("/etc/brave/policies/managed");

/** The last --load-extension line's index in lines, -1 without one. */
const lastLine = (lines: string[]) => lines.findLastIndex((l) => l.startsWith(OPTION));

/** The extensions on the last --load-extension line. */
const extensions = (text: string) => {
  const lines = text.split("\n");
  const i = lastLine(lines);
  return i < 0 ? [] : lines[i].slice(OPTION.length).split(",").filter(Boolean);
};

/** text with the extensions in extra added to its last --load-extension line (or a new one). */
function withExtensions(text: string, extra: string[]) {
  const lines = text.split("\n");
  const i = lastLine(lines);
  const have = i < 0 ? [] : extensions(text);
  const missing = extra.filter((e) => !have.includes(e));
  if (missing.length === 0) return text;
  if (i >= 0) {
    lines[i] = OPTION + [...have, ...missing].join(",");
    return lines.join("\n");
  }
  return `${text}${text === "" || text.endsWith("\n") ? "" : "\n"}${OPTION}${missing.join(",")}\n`;
}

async function install() {
  const kept = extensions(await read(FLAGS)).filter((e) => !e.startsWith(OMARCHY));
  await $`omarchy install browser brave`;
  if (!(await ready())) throw new Error("Brave isn't fully set up");
  if (kept.length > 0) {
    await Bun.write(FLAGS, withExtensions(await read(FLAGS), kept));
    const now = extensions(await read(FLAGS));
    const lost = kept.filter((e) => !now.includes(e));
    if (lost.length > 0) throw new Error(`brave-flags.conf lost ${lost.join(", ")}`);
    console.log(`Kept on Brave's --load-extension line: ${kept.join(", ")}`);
  }
}

await main(ready, install);
