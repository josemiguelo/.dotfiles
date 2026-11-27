// Omarchy's default browser (xdg-settings default-web-browser, which Omarchy's
// launchers and every XDG handler use), set the native way: `omarchy default
// browser <name>`. Arch's packages already use the desktop ids Omarchy
// expects, so no desktop-id alias is needed.
import { $, isOnPath, outputOf } from "loadout/script";
import type { Options } from "./omarchy-default-browser-arch.rules.ts";

export const check = async ({ browser }: Options) => (await outputOf($`omarchy default browser`)) === browser;

export async function install({ browser }: Options) {
  if (!isOnPath(browser)) throw new Error(`${browser} is not installed`);
  await $`omarchy default browser ${browser}`;
}
