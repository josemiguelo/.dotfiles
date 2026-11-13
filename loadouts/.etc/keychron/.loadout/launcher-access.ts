#!/usr/bin/env bun
// Keychron keyboards configurable from Keychron's web Launcher
// (launcher.keychron.com). The Launcher talks to the keyboard over WebHID,
// which needs the browser to open the keyboard's /dev/hidraw* nodes; those
// are root-only by default, so the Launcher just says "connecting" forever
// (no console error). A udev rule gives the logged-in user access to
// Keychron's (vendor 3434) hidraw nodes through uaccess — Keychron's own
// Linux instructions, and the rule Omarchy ships for the Framework 16's QMK
// modules (default/udev/framework16-qmk-hid.rules) and in open PR #9545 for
// Keychron RGB. Numbered 50- like Omarchy's, so the uaccess tag is set before
// 73-seat-late applies the ACL. Tested first with a temporary setfacl on the
// USB hidraw nodes: the Launcher connected.
// The check wants the rule in place and, when a Keychron is plugged in over
// USB, every one of its hidraw nodes readable and writable by this user.
// Modes: `check` / `install` (default).
import { accessSync, constants, existsSync, readdirSync } from "node:fs";
import { $, main, read, readTrimmed, sudoWrite } from "loadout/script";

const RULE = "/etc/udev/rules.d/50-keychron-hid.rules";
const RULE_TEXT = `# Managed by loadout (keychron-launcher-access): let the logged-in user open
# Keychron keyboards' HID nodes, so the Keychron Launcher (WebHID) can connect.
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0660", TAG+="uaccess"
`;

const ruleOk = async () => (await readTrimmed(RULE)) === RULE_TEXT.replace(/\n+$/, "");

/** /dev/hidrawN of every Keychron connected over USB (bus 0003). */
async function keychronNodes() {
  const nodes: string[] = [];
  const sys = "/sys/class/hidraw";
  for (const h of existsSync(sys) ? readdirSync(sys) : []) {
    if (/^HID_ID=0003:00003434:/m.test(await read(`${sys}/${h}/device/uevent`))) nodes.push(`/dev/${h}`);
  }
  return nodes;
}

async function accessible() {
  for (const node of await keychronNodes()) {
    try {
      accessSync(node, constants.R_OK | constants.W_OK);
    } catch {
      return false;
    }
  }
  return true;
}

const ready = async () => (await ruleOk()) && (await accessible());

async function install() {
  if (!(await ruleOk())) await sudoWrite(RULE, RULE_TEXT);
  await $`sudo udevadm control --reload`;
  // Re-run the rules for the hidraw nodes now, so a Keychron already plugged
  // in gets access without replugging.
  await $`sudo udevadm trigger --subsystem-match=hidraw --action=change`;
  await $`sudo udevadm settle`;
  if (!(await ready())) throw new Error(`${RULE} is in place but a Keychron hidraw node still isn't accessible`);
}

await main(ready, install);
