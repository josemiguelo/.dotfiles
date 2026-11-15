#!/usr/bin/env bun
// Touch ID for sudo, polkit and the lock screen, through t2-touchid (the
// t2-arch-packages package, KaiT2en's daemon): the T2's Secure Enclave matches
// the finger and the daemon hands fprintd the verdict.
//
// Fingers are enrolled in macOS only, and the Secure Enclave reports none until
// macOS has been logged into once since the T2 last lost power. The daemon
// binds them to a Linux account without a touch (T2_TOUCHID_BIND_USER in
// /etc/t2-touchid.conf); any finger enrolled in macOS then unlocks it.
//
// In order, as tested by hand on 2026-11-14 (t2-arch-packages' CLAUDE.md, item
// 9): the binding set to this user and the daemon running; fprintd listing the
// fingers; only then PAM, Omarchy's own: its fingerprint setup's
// setup_pam_config (sudo and polkit-1, `sufficient`, behind its lid-closed
// gate) and omarchy-apply-lock (the lock screen's fingerprint context and the
// fprintd resume hook). Omarchy's whole setup can't run on a T2: it finds no
// USB reader, then would enroll. Each PAM line falls through to the password
// when fprintd has no reader or the finger doesn't come.
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { $, main, ok, out, read } from "loadout/script";

const CONF = "/etc/t2-touchid.conf";
const UNIT = "t2-touchid.service";
const SETUP = "/usr/share/omarchy/bin/omarchy-setup-security-fingerprint";
const LOCK_PAM = "/etc/pam.d/omarchy-lock-fingerprint";
const USER = process.env.USER || "";
const WAIT = 30; // seconds for the daemon to bind the fingers

const bindLine = `T2_TOUCHID_BIND_USER=${USER}`;

const bound = async () => (await read(CONF)).split("\n").includes(bindLine);

const running = async () => (await ok($`systemctl -q is-enabled ${UNIT}`)) && (await ok($`systemctl -q is-active ${UNIT}`));

/** fprintd lists at least one finger for this user. */
const fingers = async () => /^\s*-\s*#\d+:/m.test(await out($`fprintd-list ${USER}`.nothrow()));

/** Omarchy's lines: pam_fprintd and its lid gate in sudo and polkit-1, and the lock's context. */
async function pam() {
  for (const file of ["/etc/pam.d/sudo", "/etc/pam.d/polkit-1"]) {
    const text = await read(file);
    if (!text.includes("pam_fprintd.so") || !text.includes("omarchy-hw-laptop-closed")) return false;
  }
  return existsSync(LOCK_PAM);
}

const ready = async () => (await bound()) && (await running()) && (await fingers()) && (await pam());

async function install() {
  if (!USER) throw new Error("USER isn't set");
  if (!existsSync(CONF)) throw new Error(`${CONF} isn't there: is t2-touchid installed?`);
  if (!(await bound())) {
    await $`sudo sed -i ${`s/^T2_TOUCHID_BIND_USER=.*/${bindLine}/`} ${CONF}`;
    if (!(await bound())) throw new Error(`${CONF} has no T2_TOUCHID_BIND_USER line to set`);
    await $`sudo systemctl enable ${UNIT}`;
    await $`sudo systemctl restart ${UNIT}`;
  } else if (!(await running())) {
    await $`sudo systemctl enable --now ${UNIT}`;
  }

  // The daemon binds within seconds of reaching the sensor; nothing to bind
  // means macOS hasn't unlocked the Secure Enclave since the T2 lost power.
  for (let i = 0; i < WAIT && !(await fingers()); i++) await Bun.sleep(1000);
  if (!(await fingers())) {
    throw new Error(
      `fprintd lists no fingers for ${USER} after ${WAIT}s. Enroll one in macOS (System Settings → Touch ID), or log into macOS once if the Mac lost power, then run this again; journalctl -u ${UNIT} says what the daemon sees`,
    );
  }

  // Omarchy's setup_pam_config, taken out of its fingerprint setup unchanged.
  const fn = (await read(SETUP)).match(/^setup_pam_config\(\) \{\n[\s\S]*?\n\}$/m)?.[0];
  if (!fn) throw new Error(`setup_pam_config isn't in ${SETUP} any more`);
  await $`bash -c ${`${fn}\nsetup_pam_config`}`;
  await $`omarchy-apply-lock`;
  if (!(await pam())) throw new Error("Omarchy's fingerprint PAM lines aren't in place after setup");
}

await main(ready, install);
