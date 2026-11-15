#!/usr/bin/env bun
// The T2 MacBook's internal keyboard and Touch Bar on KaiT2en's drivers
// (t2-touchbar-dkms) and its Touch Bar daemon (t2-touchbar), in place of
// hid-apple and the in-kernel Touch Bar drivers.
//
// t2-touchbar-dkms installs inert: its /usr/lib/modprobe.d/t2-touchbar.conf
// keeps t2hid, t2touchbar_* and t2bdrm from autoloading, since they claim the
// same devices. The switch-over is /etc/modprobe.d/t2-touchbar.conf, which
// takes that file's place: it blacklists hid_apple, hid_appletb_kbd,
// hid_appletb_bl and appletbdrm instead, and carries the keyboard options to
// t2hid (a hid-apple fork with the same ones):
//
//   swap_fn_leftctrl=1  the bottom-left corner key is Ctrl; the key labelled
//                       "control" becomes Fn (which also wakes the bar and
//                       switches its layers)
//   swap_opt_cmd=1      Alt/Super swapped, PC layout
//   fnmode              left at the default 3 (auto, 4 on this keyboard): the
//                       missing F-row stays alone, Fn+arrows are Home/End/PgUp/
//                       PgDn and Fn+backspace is Delete
//
// The keyboard has to work at the disk unlock prompt, so t2hid goes into the
// initramfs: /etc/mkinitcpio.conf.d/apple-t2.conf (Omarchy's T2 installer,
// fix-t2.sh) loads hid_apple by name there, which a blacklist doesn't stop;
// it's swapped for t2hid, and modconf copies the blacklist in for the rest.
// limine-mkinitcpio rebuilds the image and the boot entries. Before the reboot
// that applies it, nothing changes; take a snapshot first, and keep a USB
// keyboard at hand (it uses hid-generic).
//
// The daemon: the user joins the t2-touchbar group (its private seat, the
// keyboard's event node, uinput, the bar's light; a new group reaches the user
// session only after a reboot), and t2-touchbar.service is enabled globally,
// which also lets t2-touchbar-attach switch the bar to its screen at boot.
//
// /boot isn't readable unprivileged, so whether the image is current shows in
// the running system: t2hid loaded with these options. Until the reboot, the
// check says not done.
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { $, main, ok, out, read, readTrimmed, sudoWrite } from "loadout/script";

const MODPROBE = "/etc/modprobe.d/t2-touchbar.conf";
const INITRAMFS = "/etc/mkinitcpio.conf.d/apple-t2.conf";
const PARAMS = "/sys/module/t2hid/parameters";
const GROUP = "t2-touchbar";
const UNIT = "t2-touchbar.service";
const USER = process.env.USER || "";

const MODPROBE_TEXT = `# Managed by loadout (t2-touchbar-switch): the internal keyboard and Touch Bar
# on t2hid, t2touchbar_kbd/_bl and t2bdrm (t2-touchbar-dkms), in place of the
# in-kernel drivers. Takes the place of the package's file of the same name in
# /usr/lib/modprobe.d, which keeps them off. Delete it (and put hid_apple back
# in ${INITRAMFS}, then limine-mkinitcpio) to switch back.
blacklist hid_apple
blacklist hid_appletb_kbd
blacklist hid_appletb_bl
blacklist appletbdrm
options t2hid swap_fn_leftctrl=1
options t2hid swap_opt_cmd=1
`;
// fnmode 3 is the default, what the absent line yields.
const LIVE: [string, string][] = [
  ["fnmode", "3"],
  ["swap_fn_leftctrl", "1"],
  ["swap_opt_cmd", "1"],
];

const modprobeOk = async () => (await readTrimmed(MODPROBE)) === MODPROBE_TEXT.replace(/\n+$/, "");

/** The initramfs MODULES line names t2hid, not hid_apple. */
async function initramfsOk() {
  const words = (await read(INITRAMFS)).split(/[\s()]+/);
  return words.includes("t2hid") && !words.includes("hid_apple");
}

const inGroup = async () => (await out($`getent group ${GROUP}`.nothrow())).trim().split(":")[3]?.split(",").includes(USER) ?? false;
const enabled = () => ok($`systemctl --global is-enabled --quiet ${UNIT}`);
const loaded = () => existsSync(PARAMS);

async function liveOk() {
  if (!loaded()) return false;
  for (const [param, value] of LIVE) if ((await readTrimmed(`${PARAMS}/${param}`)) !== value) return false;
  return true;
}

const ready = async () => (await modprobeOk()) && (await initramfsOk()) && (await inGroup()) && (await enabled()) && (await liveOk());

async function install() {
  if (!USER) throw new Error("USER isn't set");
  if (!(await ok($`pacman -Q t2-touchbar-dkms t2-touchbar`))) throw new Error("t2-touchbar-dkms and t2-touchbar aren't installed");
  if (!existsSync(INITRAMFS)) throw new Error(`${INITRAMFS} isn't there: this is for an Omarchy T2 install (fix-t2.sh writes it)`);

  let rebuild = false;
  if (!(await modprobeOk())) {
    await sudoWrite(MODPROBE, MODPROBE_TEXT);
    rebuild = true;
  }
  if (!(await initramfsOk())) {
    await $`sudo sed -i -E ${"/^MODULES/{s/(^|[ (])hid_apple([ )]|$)/\\1t2hid\\2/; /[ (]t2hid[ )]/! s/\\)$/ t2hid)/}"} ${INITRAMFS}`;
    if (!(await initramfsOk())) throw new Error(`couldn't put t2hid in place of hid_apple in ${INITRAMFS}`);
    rebuild = true;
  }
  // Running on t2hid with other options: the image is stale.
  if (loaded() && !(await liveOk())) rebuild = true;
  if (rebuild) await $`sudo limine-mkinitcpio`;

  if (!(await inGroup())) await $`sudo usermod -aG ${GROUP} ${USER}`;
  if (!(await enabled())) await $`sudo systemctl --global enable ${UNIT}`;

  if (!loaded()) {
    console.log("Reboot to switch the keyboard and Touch Bar over (keep a USB keyboard at hand for the unlock prompt). Run this again after.");
    return;
  }
  for (const [param, value] of LIVE) {
    if ((await readTrimmed(`${PARAMS}/${param}`)) !== value) await $`sudo tee ${`${PARAMS}/${param}`} < ${Buffer.from(`${value}\n`)}`.quiet();
  }
}

await main(ready, install);
