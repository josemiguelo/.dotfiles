#!/usr/bin/env bun
// Surfingkeys is gone from the repo: this takes out what it left on a
// machine. Its files (~/.config/surfingkeys: surfingkeys.js and the "Split
// view keys" extension) go through .chezmoiremove; what chezmoi can't reach is
// the extension's entry on Brave's --load-extension line in
// ~/.config/brave-flags.conf, which surfingkeys-split-view added and
// omarchy-brave carried. Left there, Brave would fail to load it from a
// missing folder at every start. Brave reads the file when it starts.
//
// The Surfingkeys extension itself, installed by hand from the Chrome Web
// Store, lives in Brave's signed profile, out of reach: install says to
// remove it in brave://extensions when it's there, and the check doesn't
// count it.
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { main, read } from "loadout/script";

const CONFIG = process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`;
const FLAGS = `${CONFIG}/brave-flags.conf`;
const EXT = `${CONFIG}/surfingkeys/split-view`;
const OPTION = "--load-extension=";
const SURFINGKEYS_ID = "gfbliohnnapiefjpjlpjnehglfpaknnc";
const BRAVE_EXTENSIONS = `${CONFIG}/BraveSoftware/Brave-Browser/Default/Extensions`;

/** The flags file's lines with the extension off every --load-extension line, and empty ones dropped. */
function without(text: string) {
  return text
    .split("\n")
    .flatMap((line) => {
      if (!line.startsWith(OPTION)) return [line];
      const kept = line.slice(OPTION.length).split(",").filter((e) => e && e !== EXT);
      return kept.length ? [OPTION + kept.join(",")] : [];
    })
    .join("\n");
}

async function ready() {
  const text = await read(FLAGS);
  return without(text) === text;
}

async function install() {
  if (!(await ready())) {
    await Bun.write(FLAGS, without(await read(FLAGS)));
    console.error("Restart Brave so it stops loading the Split view keys extension");
  }
  if (existsSync(`${BRAVE_EXTENSIONS}/${SURFINGKEYS_ID}`)) {
    console.error(`Surfingkeys is still installed in Brave: remove it at brave://extensions/?id=${SURFINGKEYS_ID}`);
  }
}

await main(ready, install);
