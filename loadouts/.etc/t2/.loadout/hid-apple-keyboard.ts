#!/usr/bin/env bun
// Internal keyboard behaviour on the MacBookPro16,1 (T2) on Omarchy:
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
// What differs on Omarchy:
//   - Its installer writes this file first, once, as `fnmode=2` (so F-keys on
//     external Apple-like keyboards are always F-keys); it is replaced here.
//   - hid_apple loads from the initramfs (apple-t2.conf puts it in MODULES,
//     and the modconf hook copies modprobe.d in), built by mkinitcpio through
//     Limine: `limine-mkinitcpio` rebuilds it AND the boot entries, which a
//     bare `mkinitcpio -P` would leave stale.
//   - /boot isn't readable unprivileged, so the image's age can't be compared
//     with the file's. The live parameters tell instead: after a boot they are
//     what the initramfs loaded, so a mismatch means the image is stale.
import { $, main, readTrimmed, sudoWrite } from "loadout/script";

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

async function install() {
  let rebuild = false;
  if (!(await confOk())) {
    await sudoWrite(CONF, WANT);
    rebuild = true;
  }
  // The image that booted didn't carry the file's values: rebuild it too.
  if (!(await liveOk())) rebuild = true;
  if (rebuild) await $`sudo limine-mkinitcpio`;
  await applyLive();
}

await main(ready, install);
