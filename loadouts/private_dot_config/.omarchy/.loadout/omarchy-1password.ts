#!/usr/bin/env bun
// 1Password, set up by Omarchy's own installer
// (omarchy-install-service-1password): the app and the CLI from Omarchy's
// repo, plus the managed-extension entry that makes Chromium install the
// 1Password extension. The installer also opens 1Password when it's done.
//
// 1Password reads the display scale itself and, on a scaled monitor, draws
// its contents larger than the windows it asks for: Quick Access comes up
// cut off. Omarchy's launcher passes --force-device-scale-factor=1; so do
// the login autostart entry 1Password writes (its "Start at login", rewritten
// here when it lacks the flag, never created) and Ctrl+Shift+Space, which
// opens Quick Access from a block in ~/.config/hypr/bindings.lua — Wayland
// gives 1Password no global shortcut of its own.
// The installer opens 1Password as it finishes, and the app writes its
// autostart entry a few seconds later, without the flag: rewritten before it
// appeared, it stayed pending until the next run. So after installing, the
// script waits (up to half a minute, while 1Password runs) for that entry.
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { $, has, main, ok, read } from "#loadout";
import { BINDINGS, HOME, binds, block, blockIn, liveInstance, noConfigErrors, probe, reload, writeBlock } from "#hypr";

const NAME = "omarchy-1password";
const EXTENSION = "/usr/share/chromium/extensions/aeblfdkhhhdcdjpifhhbdiojplfjncoa.json";
const AUTOSTART = `${HOME}/.config/autostart/com.onepassword.OnePassword.desktop`;
const FLAG = "--force-device-scale-factor=1";
const KEY = "CTRL + SHIFT + SPACE";
const QUICK_ACCESS = `1password ${FLAG} --quick-access`;
const DESCRIPTION = "1Password Quick Access";
const MASK = 5; // CTRL 4 + SHIFT 1

const body = [
  "-- Ctrl+Shift+Space opens 1Password's Quick Access",
  "-- (loadouts/private_dot_config/.omarchy/.loadout/omarchy-1password.ts rewrites this block).",
  `hl.unbind("${KEY}")`,
  `o.bind("${KEY}", "${DESCRIPTION}", o.launch("${QUICK_ACCESS}"))`,
];

/** Both packages; the extension entry only matters where Chromium is installed. */
const installed = async () =>
  (await ok($`pacman -Q 1password`)) && (await ok($`pacman -Q 1password-cli`)) && (!has("chromium") || existsSync(EXTENSION));

/**
 * The entry 1Password writes on its first start, a few seconds after the
 * installer opens it: waited for while it runs, then left to the check
 * (none in time is start at login off, which is fine).
 */
async function settleAutostart() {
  for (let i = 0; i < 30 && !existsSync(AUTOSTART); i++) {
    if (!(await ok($`pgrep -x 1password`))) return;
    await Bun.sleep(1000);
  }
}

/** No autostart entry (start at login off) is fine; one without the flag isn't. */
const autostartScaled = async () => !existsSync(AUTOSTART) || new RegExp(`^Exec=.*${FLAG}`, "m").test(await read(AUTOSTART));

const bound = async () =>
  (await blockIn(BINDINGS, NAME)).join("\n") === block(NAME, body).join("\n") && (await probe(`bind:${KEY}`)) === `uwsm-app -- ${QUICK_ACCESS}`;

const ready = async () => (await installed()) && (await autostartScaled()) && (await bound());

async function install() {
  if (!(await installed())) {
    await $`omarchy-install-service-1password`;
    await settleAutostart();
  }
  if (!(await installed())) throw new Error("1Password isn't fully set up");
  if (!(await autostartScaled())) {
    const entry = (await read(AUTOSTART)).replace(/^Exec=(\S*1password)/gm, `Exec=$1 ${FLAG}`);
    await Bun.write(AUTOSTART, entry);
  }
  await writeBlock(BINDINGS, NAME, body);
  if (!(await ready())) throw new Error("1Password's autostart flag or Quick Access key isn't in place after install");
  const sig = await liveInstance();
  if (sig) {
    await reload(sig);
    await noConfigErrors(sig);
    const got = (await binds(sig)).filter((b) => b.modmask === MASK && b.key === "SPACE").map((b) => b.description).join("|");
    if (got !== DESCRIPTION) throw new Error(`the running Hyprland binds Ctrl+Shift+Space to '${got}', not '${DESCRIPTION}'`);
  } else {
    console.log("Hyprland isn't reachable from here; the key works at the next login.");
  }
  console.log("A 1Password already running keeps its scale until it restarts.");
}

await main(ready, install);
