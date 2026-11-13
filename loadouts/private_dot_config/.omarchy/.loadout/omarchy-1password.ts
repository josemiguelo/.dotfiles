#!/usr/bin/env bun
// 1Password, set up by Omarchy's own installer
// (omarchy-install-service-1password): the app and the CLI from Omarchy's
// repo, plus the managed-extension entry that makes Chromium install the
// 1Password extension. The installer also opens 1Password when it's done.
//
// 1Password reads the display scale itself and, on a scaled monitor, draws
// its contents larger than the windows it asks for: Quick Access comes up
// cut off. Omarchy's launcher and the packaged .desktop pass
// --force-device-scale-factor=1; so do the login autostart entry written
// here and Ctrl+Shift+Space, which opens Quick Access from a block in
// ~/.config/hypr/bindings.lua (Wayland gives 1Password no global shortcut of
// its own).
//
// Login startup is ours, not 1Password's: while its "Start at login" is on,
// the app regenerates ~/.config/autostart/com.onepassword.OnePassword.desktop
// from its own template (no flag) at every start, so an edited entry lasted
// one login. With it off, the app deletes that entry and leaves
// 1password-unscaled.desktop (a name it doesn't know) alone. The switch is
// `app.startAtLogin` in its settings.json, but the app signs every value
// there (authTags), so it can't be written from here: `install` asks for it
// to be turned off in the app and waits (ONEPASSWORD_WAIT seconds, default
// 900, as onepassword-cli does), then writes its own entry.
// Modes: `check` / `install` (default).
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { $, has, main, ok, read } from "loadout/script";
import { BINDINGS, HOME, binds, block, blockIn, liveInstance, noConfigErrors, probe, reload, writeBlock } from "#hypr";

const NAME = "omarchy-1password";
const EXTENSION = "/usr/share/chromium/extensions/aeblfdkhhhdcdjpifhhbdiojplfjncoa.json";
const AUTOSTART_DIR = `${HOME}/.config/autostart`;
const APP_AUTOSTART = `${AUTOSTART_DIR}/com.onepassword.OnePassword.desktop`;
const OUR_AUTOSTART = `${AUTOSTART_DIR}/1password-unscaled.desktop`;
const SETTINGS = `${HOME}/.config/1Password/settings/settings.json`;
const FLAG = "--force-device-scale-factor=1";
const KEY = "CTRL + SHIFT + SPACE";
const QUICK_ACCESS = `1password ${FLAG} --quick-access`;
const DESCRIPTION = "1Password Quick Access";
const MASK = 5; // CTRL 4 + SHIFT 1
const WAIT = Number(process.env.ONEPASSWORD_WAIT || 900);

const body = [
  "-- Ctrl+Shift+Space opens 1Password's Quick Access",
  "-- (loadouts/private_dot_config/.omarchy/.loadout/omarchy-1password.ts rewrites this block).",
  `hl.unbind("${KEY}")`,
  `o.bind("${KEY}", "${DESCRIPTION}", o.launch("${QUICK_ACCESS}"))`,
];

const entry = `[Desktop Entry]
# Written by loadout (loadouts/private_dot_config/.omarchy/.loadout/omarchy-1password.ts):
# 1Password's own "Start at login" entry drops the scale flag, so it's off and this starts it.
Name=1Password
Exec=/opt/1Password/1password ${FLAG} --silent
Terminal=false
Type=Application
Icon=1password
StartupWMClass=com.onepassword.OnePassword
`;

/** Both packages; the extension entry only matters where Chromium is installed. */
const installed = async () =>
  (await ok($`pacman -Q 1password`)) && (await ok($`pacman -Q 1password-cli`)) && (!has("chromium") || existsSync(EXTENSION));

/** The app's "Start at login" is off: absent means its default, on. */
async function appStartAtLoginOff() {
  try {
    return JSON.parse(await read(SETTINGS))?.["app.startAtLogin"] === false;
  } catch {
    return false;
  }
}

/** Ours in place and the app's gone, so login starts one 1Password, scaled right. */
const autostartOurs = async () => (await read(OUR_AUTOSTART)) === entry && !existsSync(APP_AUTOSTART);

const bound = async () =>
  (await blockIn(BINDINGS, NAME)).join("\n") === block(NAME, body).join("\n") && (await probe(`bind:${KEY}`)) === `uwsm-app -- ${QUICK_ACCESS}`;

const ready = async () => (await installed()) && (await appStartAtLoginOff()) && (await autostartOurs()) && (await bound());

/** The switch can't be flipped from here (signed settings): ask for it and wait. */
async function waitForStartAtLoginOff() {
  if (await appStartAtLoginOff()) return;
  console.error(`
==> Waiting for 1Password's "Start at login" to go off (up to ${WAIT}s). In the 1Password app:
      Settings → General → turn off "Start at login"
    loadout starts it at login instead, unscaled. This goes on by itself once it's off.`);
  const deadline = Date.now() + WAIT * 1000;
  while (!(await appStartAtLoginOff())) {
    if (Date.now() >= deadline) {
      throw new Error(`gave up waiting after ${WAIT}s; turn off 1Password's "Start at login", then run this again`);
    }
    await Bun.sleep(3000);
  }
  console.error(`${NAME}: 1Password's "Start at login" is off`);
}

async function install() {
  if (!(await installed())) await $`omarchy-install-service-1password`;
  if (!(await installed())) throw new Error("1Password isn't fully set up");
  await waitForStartAtLoginOff();
  // The app deletes its entry when the switch goes off; one left from before goes here.
  rmSync(APP_AUTOSTART, { force: true });
  mkdirSync(AUTOSTART_DIR, { recursive: true });
  await Bun.write(OUR_AUTOSTART, entry);
  await writeBlock(BINDINGS, NAME, body);
  if (!(await ready())) throw new Error("1Password's autostart entry or Quick Access key isn't in place after install");
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
