// Touch ID for sudo, polkit and the lock screen, through t2-touchid (the
// t2-arch-packages package, KaiT2en's daemon): the T2's Secure Enclave matches
// the finger and the daemon hands fprintd the verdict.
//
// Fingers are enrolled in macOS only, and the Secure Enclave reports none until
// macOS has been logged into once since the T2 last lost power. Turning Touch
// ID on is Omarchy's own fingerprint setup, as on any laptop with a reader: the
// package names the T2's reader in /usr/share/omarchy-platform/fingerprint-readers
// (the daemon writes /run/t2-touchid/reader, `ready` or the reason it isn't),
// so the setup finds it; its enroll step binds the macOS finger to this account
// with one touch, then it verifies, then adds the PAM lines (sudo and polkit-1,
// behind its lid-closed gate) and the lock screen's (omarchy-apply-lock).
// Omarchy's removal undoes it. The daemon's automatic binding
// (T2_TOUCHID_BIND_USER) stays off: it would bind again at every daemon start
// and bring a removed fingerprint back.
//
// install: the daemon running and not binding; with no finger bound, Omarchy's
// setup (asks for two touches); with one bound but no PAM lines, just Omarchy's
// PAM steps (setup_pam_config and omarchy-apply-lock).
import { existsSync } from "node:fs";
import { $, succeeds, outputOf, read, readTrimmed } from "loadout/script";

const CONF = "/etc/t2-touchid.conf";
const UNIT = "t2-touchid.service";
const READER = "/run/t2-touchid/reader";
const SETUP = "/usr/share/omarchy/bin/omarchy-setup-security-fingerprint";
const LOCK_PAM = "/etc/pam.d/omarchy-lock-fingerprint";
const USER = process.env.USER || "";
const WAIT = 30; // seconds for the daemon to reach the sensor

const noBinding = async () => (await read(CONF)).split("\n").includes("T2_TOUCHID_BIND_USER=none");

// The fork's install enables the daemon; here it only has to be running.
const running = () => succeeds($`systemctl -q is-active ${UNIT}`);

/** fprintd lists at least one finger for this user. */
const fingers = async () => /^\s*-\s*#\d+:/m.test(await outputOf($`fprintd-list ${USER}`.nothrow()));

/** Omarchy's lines: pam_fprintd and its lid gate in sudo and polkit-1, and the lock's context. */
async function pam() {
  for (const file of ["/etc/pam.d/sudo", "/etc/pam.d/polkit-1"]) {
    const text = await read(file);
    if (!text.includes("pam_fprintd.so") || !text.includes("omarchy-hw-laptop-closed")) return false;
  }
  return existsSync(LOCK_PAM);
}

export const check = async () => (await noBinding()) && (await running()) && (await fingers()) && (await pam());

/** The daemon says the sensor answers and macOS has fingers enrolled, or why not. */
async function waitForReader() {
  for (let i = 0; i < WAIT && (await readTrimmed(READER)) !== "ready"; i++) await Bun.sleep(1000);
  const state = (await readTrimmed(READER)) || "no status";
  if (state === "ready") return;
  const why =
    state === "no-fingers"
      ? "macOS has no finger enrolled, or hasn't unlocked the Secure Enclave since the Mac lost power: enroll one in macOS (System Settings → Touch ID), or log into macOS once"
      : `the daemon says '${state}' (journalctl -u ${UNIT})`;
  throw new Error(`Touch ID isn't ready after ${WAIT}s: ${why}; then run this again`);
}

export async function install() {
  if (!USER) throw new Error("USER isn't set");
  if (!existsSync(CONF)) throw new Error(`${CONF} isn't there: is t2-touchid installed?`);
  if (!(await noBinding())) {
    await $`sudo sed -i ${"s/^T2_TOUCHID_BIND_USER=.*/T2_TOUCHID_BIND_USER=none/"} ${CONF}`;
    if (!(await noBinding())) throw new Error(`${CONF} has no T2_TOUCHID_BIND_USER line to set`);
    await $`sudo systemctl restart ${UNIT}`;
  } else if (!(await running())) {
    await $`sudo systemctl start ${UNIT}`;
  }
  await waitForReader();

  if (!(await fingers())) {
    // Omarchy's setup, on this terminal: one touch binds the finger, one verifies.
    await $`${SETUP}`;
  } else if (!(await pam())) {
    // A finger bound already (by an earlier setup): only Omarchy's PAM steps.
    const fn = (await read(SETUP)).match(/^setup_pam_config\(\) \{\n[\s\S]*?\n\}$/m)?.[0];
    if (!fn) throw new Error(`setup_pam_config isn't in ${SETUP} any more`);
    await $`bash -c ${`${fn}\nsetup_pam_config`}`;
    await $`omarchy-apply-lock`;
  }
  if (!(await check())) throw new Error("Touch ID isn't fully set up after Omarchy's fingerprint setup");
}
