#!/usr/bin/env bun
// Omarchy's default browser (xdg-settings default-web-browser, which Omarchy's
// launchers and every XDG handler use), set the native way: `omarchy default
// browser <name>`. Arch's packages already use the desktop ids Omarchy
// expects, so no desktop-id alias is needed.
// usage: omarchy-default-browser-arch.ts <browser>
import { $, has, run } from "#loadout";

await run(async (browser) => {
  if (!browser) throw new Error("usage: omarchy-default-browser-arch.ts <browser>");
  if (!has(browser)) throw new Error(`${browser} is not installed`);
  await $`omarchy default browser ${browser}`;
});
