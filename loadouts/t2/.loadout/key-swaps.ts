// The owner's key layout on the T2 MacBook's internal keyboard, through t2hid
// (KaiT2en's hid-apple fork, which the Omarchy fork's install already puts in
// place of hid-apple, in the initramfs too):
//
//   swap_fn_leftctrl=1  the bottom-left corner key is Ctrl; the key labelled
//                       "control" becomes Fn (which also wakes the Touch Bar
//                       and switches its layers)
//   swap_opt_cmd=1      Alt/Super swapped, PC layout
//   fnmode              left at the default 3 (auto, 4 on this keyboard): the
//                       missing F-row stays alone, Fn+arrows are Home/End/PgUp/
//                       PgDn and Fn+backspace is Delete
//
// Written to their own file; modconf copies it into the initramfs, so the
// layout holds at the disk unlock prompt too (limine-mkinitcpio rebuilds it).
// Applied to the running keyboard at once as well: t2hid's parameters are
// writable.
//
// Before 2026-11-17 the dotfiles did the whole switch-over and wrote these
// options into /etc/modprobe.d/t2-touchbar.conf, the fork's file: that file is
// put back to the fork's text here, once.
import { existsSync } from "node:fs";
import { $, readTrimmed, sudoWrite } from "loadout/script";

const SWAPS = "/etc/modprobe.d/t2hid-swaps.conf";
const FORK_FILE = "/etc/modprobe.d/t2-touchbar.conf";
const PARAMS = "/sys/module/t2hid/parameters";

const SWAPS_TEXT = `# Managed by loadout (t2-key-swaps): the owner's layout on the internal
# keyboard (t2hid): Ctrl in the bottom-left corner, Fn where "control" is, and
# Alt/Super swapped.
options t2hid swap_fn_leftctrl=1
options t2hid swap_opt_cmd=1
`;
// The Omarchy fork's text (install/hardware/apple/fix-t2.sh).
const FORK_TEXT = `# Omarchy (fix-t2.sh): the internal keyboard and Touch Bar on t2hid,
# t2touchbar_kbd/_bl and t2bdrm (t2-touchbar-dkms), in place of the in-kernel
# drivers. Takes the place of the package's file of the same name in
# /usr/lib/modprobe.d, which keeps them off.
blacklist hid_apple
blacklist hid_appletb_kbd
blacklist hid_appletb_bl
blacklist appletbdrm
`;
// fnmode 3 is the default, what the absent line yields.
const LIVE: [string, string][] = [
  ["fnmode", "3"],
  ["swap_fn_leftctrl", "1"],
  ["swap_opt_cmd", "1"],
];

const swapsOk = async () => (await readTrimmed(SWAPS)) === SWAPS_TEXT.replace(/\n+$/, "");
const oldCopy = async () => (await readTrimmed(FORK_FILE)).startsWith("# Managed by loadout (t2-touchbar-switch)");
const loaded = () => existsSync(PARAMS);

async function liveOk() {
  if (!loaded()) return false;
  for (const [param, value] of LIVE) if ((await readTrimmed(`${PARAMS}/${param}`)) !== value) return false;
  return true;
}

export const check = async () => (await swapsOk()) && !(await oldCopy()) && (await liveOk());

export async function install() {
  if (!loaded()) throw new Error("t2hid isn't loaded: this is for a T2 Mac installed from the Omarchy fork");
  let rebuild = false;
  if (!(await swapsOk())) {
    await sudoWrite(SWAPS, SWAPS_TEXT);
    rebuild = true;
  }
  if (await oldCopy()) {
    await sudoWrite(FORK_FILE, FORK_TEXT);
    rebuild = true;
  }
  if (rebuild) await $`sudo limine-mkinitcpio`;
  for (const [param, value] of LIVE) {
    if ((await readTrimmed(`${PARAMS}/${param}`)) !== value) await $`sudo tee ${`${PARAMS}/${param}`} < ${Buffer.from(`${value}\n`)}`.quiet();
  }
}
