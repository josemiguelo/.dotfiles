#!/usr/bin/env bun
// Internal keyboard behaviour on the MacBookPro16,1 (T2).
//
//   swap_fn_leftctrl=1  bottom-left corner key acts as Ctrl; the key labelled
//                       "control" becomes Fn (and so toggles the touchbar
//                       between media keys and F1-F12, via hid_appletb_kbd).
//   swap_opt_cmd=1      Alt/Super swapped, PC layout.
//   fnmode              deliberately NOT set -> module default 3 (auto), which
//                       resolves to 4 for this keyboard (APPLE_DISABLE_FKEYS on
//                       WELLSPRINGT2_J152F). That leaves the non-existent F-row
//                       alone but keeps Fn+arrows = Home/End/PgUp/PgDn and
//                       Fn+backspace = Delete.
//
// The live parameters matter as much as the file: hid_apple is loaded from the
// initramfs (the T2 keyboard comes up over t2bce_vhci in early boot), so a
// stale initramfs keeps old values alive across a reboot and modprobe.d is
// never consulted again. check therefore verifies BOTH, and install
// regenerates the initramfs whenever the conf is newer than it.
import { existsSync, statSync } from "node:fs";
import { release } from "node:os";
import { $, main, readTrimmed, sudoWrite } from "#loadout";

const CONF = "/etc/modprobe.d/hid_apple.conf";
const PARAMS = "/sys/module/hid_apple/parameters";
const WANT = `options hid_apple swap_fn_leftctrl=1
options hid_apple swap_opt_cmd=1
`;
// fnmode 3 is the module default; it is what the absent conf line yields.
const LIVE: [string, string][] = [
  ["fnmode", "3"],
  ["swap_fn_leftctrl", "1"],
  ["swap_opt_cmd", "1"],
];

const confOk = async () => (await readTrimmed(CONF)) === WANT.replace(/\n+$/, "");
const wantParam = async (param: string, value: string) => (await readTrimmed(`${PARAMS}/${param}`)) === value;

async function liveOk() {
  for (const [param, value] of LIVE) if (!(await wantParam(param, value))) return false;
  return true;
}

/** Apply to the already-loaded module so no reboot is needed. */
async function applyLive() {
  for (const [param, value] of LIVE) {
    if (!(await wantParam(param, value))) await $`sudo tee ${`${PARAMS}/${param}`} < ${Buffer.from(`${value}\n`)}`.quiet();
  }
}

const ready = async () => (await confOk()) && (await liveOk());

/** The conf is newer than the running kernel's initramfs (or there's none): dracut has to rebuild it. */
function initramfsStale() {
  const image = `/boot/initramfs-${release()}.img`;
  return !existsSync(image) || statSync(CONF).mtimeMs > statSync(image).mtimeMs;
}

async function install() {
  if (!(await confOk())) await sudoWrite(CONF, WANT);
  if (initramfsStale()) await $`sudo dracut -f`;
  await applyLive();
}

await main(ready, install);
