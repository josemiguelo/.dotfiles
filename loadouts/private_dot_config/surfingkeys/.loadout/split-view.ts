#!/usr/bin/env bun
// The "Split view keys" extension (~/.config/surfingkeys/split-view) on
// Brave's --load-extension line in ~/.config/brave-flags.conf. Omarchy writes
// that file and loads its own extensions on that line, and Chromium reads only
// the last --load-extension, so this joins its list. If Omarchy rewrites the
// file, `check` fails and `install` adds it again. Brave reads the file when it
// starts. Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { main, read } from "#loadout";

const CONFIG = process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`;
const FLAGS = `${CONFIG}/brave-flags.conf`;
const EXT = `${CONFIG}/surfingkeys/split-view`;
const OPTION = "--load-extension=";

/** The flags file's lines, and the index of its last --load-extension line (-1 without one). */
async function flags() {
  const lines = (await read(FLAGS)).split("\n");
  return { lines, last: lines.findLastIndex((l) => l.startsWith(OPTION)) };
}

async function ready() {
  const { lines, last } = await flags();
  return last >= 0 && lines[last].slice(OPTION.length).split(",").includes(EXT);
}

async function install() {
  if (await ready()) return;
  if (!existsSync(FLAGS)) throw new Error(`${FLAGS} is missing: set up Brave first`);
  const { lines, last } = await flags();
  if (last >= 0) {
    lines[last] += `,${EXT}`;
    await Bun.write(FLAGS, lines.join("\n"));
  } else {
    const text = await read(FLAGS);
    await Bun.write(FLAGS, `${text}${text === "" || text.endsWith("\n") ? "" : "\n"}${OPTION}${EXT}\n`);
  }
  console.error("Restart Brave to load the Split view keys extension");
}

await main(ready, install);
