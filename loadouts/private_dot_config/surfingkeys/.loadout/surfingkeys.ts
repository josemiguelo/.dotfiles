#!/usr/bin/env bun
// Surfingkeys in Brave's Default profile, allowed to read file URLs so it can
// load ~/.config/surfingkeys/surfingkeys.js. Brave keeps both in its profile
// (and signs its preferences), so nothing here can set them: `install` lists
// the steps to do in Brave. The "Load settings from" path itself lives in the
// extension's LevelDB storage, which `check` doesn't read.
// Modes: `check` / `install` (default).
import { main, read } from "#loadout";

const ID = "gfbliohnnapiefjpjlpjnehglfpaknnc";
const CONFIG = process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`;
const PROFILE = `${CONFIG}/BraveSoftware/Brave-Browser/Default`;
const SETTINGS = `${CONFIG}/surfingkeys/surfingkeys.js`;

/** File URL access granted, in either of the profile's preference files. */
async function ready() {
  for (const prefs of [`${PROFILE}/Preferences`, `${PROFILE}/Secure Preferences`]) {
    try {
      if (JSON.parse(await read(prefs))?.extensions?.settings?.[ID]?.newAllowFileAccess === true) return true;
    } catch {
      // Missing or unreadable: the other file may still say so.
    }
  }
  return false;
}

await main(ready, async () => {
  if (await ready()) return;
  throw new Error(`Surfingkeys needs setting up in Brave, by hand:
  1. Install it: https://chromewebstore.google.com/detail/surfingkeys/${ID}
  2. brave://extensions/?id=${ID} → turn on "Allow access to file URLs"
  3. Surfingkeys' settings → Advanced mode → "Load settings from":
     file://${SETTINGS}`);
});
