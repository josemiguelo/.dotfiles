#!/usr/bin/env bun
// The 1Password CLI reaching an account through the desktop app (Settings →
// Developer → "Integrate with 1Password CLI"). Steps that read secrets with
// `op` (intentional-sync, kait2en-dev, t2-bcm-firmware) run after this.
// `check` asks only for the accounts list, which needs no approval prompt:
// it says the integration is set up, not that the app is unlocked right now.
// The app's switch can't be flipped from here, so `install` waits on purpose:
// it says what to do, polls until the integration shows up, then asks for
// the vaults once in the open, so its approval prompt is answered here, not
// behind a later step's (op keeps that approval for a while, so the steps
// after this read without asking again). It gives up after ONEPASSWORD_WAIT
// seconds (default 900; 0 doesn't wait).
// Modes: `check` / `install` (default).
import { $, main, ok } from "loadout/script";
import { opConnected, opUnlocked } from "#onepassword";

const WAIT = Number(process.env.ONEPASSWORD_WAIT || 900);
const FLAG = "--force-device-scale-factor=1";

/**
 * The app has to be running for the integration; Omarchy's installer opens it,
 * but it may have been closed since. Started detached, unscaled as everywhere.
 */
async function openApp() {
  if (!Bun.which("1password") || (await ok($`pgrep -x 1password`))) return;
  if (!process.env.WAYLAND_DISPLAY && !process.env.DISPLAY) return;
  const argv = Bun.which("uwsm-app") ? ["setsid", "uwsm-app", "--", "1password", FLAG] : ["setsid", "1password", FLAG];
  Bun.spawn(argv, { stdio: ["ignore", "ignore", "ignore"] }).unref();
}

async function approve() {
  await opUnlocked("onepassword-cli");
  console.error("onepassword-cli: the CLI is connected");
}

async function install() {
  if (await opConnected()) return approve();
  if (!Bun.which("op")) throw new Error("onepassword-cli: op isn't installed");
  await openApp();
  console.error(`
==> Waiting for the 1Password CLI integration (up to ${WAIT}s). In the 1Password app:
      1. sign in to your account
      2. Settings → Developer → turn on "Integrate with 1Password CLI"
    This goes on by itself once it's on.`);
  const deadline = Date.now() + WAIT * 1000;
  let last = -1;
  while (!(await opConnected())) {
    if (Date.now() >= deadline) {
      throw new Error(`onepassword-cli: gave up waiting after ${WAIT}s; turn the integration on, then run this again`);
    }
    const left = Math.floor((deadline - Date.now()) / 60000);
    if (left !== last) {
      console.error(`    still waiting (about ${left}m left)…`);
      last = left;
    }
    await Bun.sleep(3000);
  }
  console.error("onepassword-cli: integration is on");
  await approve();
}

await main(opConnected, install);
