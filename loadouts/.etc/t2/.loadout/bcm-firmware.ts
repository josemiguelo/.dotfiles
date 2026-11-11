#!/usr/bin/env bun
// The T2 Wi-Fi/Bluetooth firmware (docs/t2-macbook.md). Only macOS ships it,
// and it can't go into this public repo. Two sources, in order:
//
// 1. The macOS volume, through apple-bcm-firmware-fetcher (Omarchy's
//    installer, install/hardware/apple/fix-t2.sh): it mounts the volume
//    read-only with the APFS driver (linux-apfs-rw-dkms on linux-omarchy) and
//    copies the firmware to /lib/firmware/brcm, listing what it copied in
//    $STATE. fix-t2.sh also enables t2-wifi-firmware.service, which runs it on
//    the installed system's boots until $STATE exists: the run during an ISO
//    install happens in a chroot that can't load the installed kernel's APFS
//    driver.
// 2. With no macOS volume: apple-bcm-firmware 14.0-1, a package that has left
//    the repos and conflicts with the fetcher. It is a document in 1Password
//    (Personal vault, titled by its file name), and a copy verified against
//    SHA256 below is kept at $COPY, outside the pacman cache paccache trims.
//
// Whichever package provides the firmware stays explicitly installed: from
// Omarchy 4.5 `omarchy-update` removes orphans without asking.
//
// check: the fetcher installed explicitly with its firmware fetched, or the
// fallback package installed explicitly with all its files and the copy in
// place. It never asks 1Password anything.
// install, only when check fails: the fetcher when a macOS volume is there
// (installed if missing, replacing the fallback package), else the fallback
// (from the pacman cache's copy or 1Password, which needs a network: USB
// tethering or a USB Ethernet adapter); then the Wi-Fi driver reloads.
// Modes: `check` / `install` (default).
import { existsSync, statSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { $, main, ok } from "#loadout";
import { opUnlocked } from "#onepassword";

const FETCHER = "apple-bcm-firmware-fetcher";
const STATE = "/var/lib/apple-bcm-firmware-fetcher/installed-files";
const PACKAGE = "apple-bcm-firmware";
const FILE = "apple-bcm-firmware-14.0-1-any.pkg.tar.zst";
const SHA256 = "f2cd47d9e3fb9658f16997b2d9ace3033b57925b8c6ddd86ccc3d07d0c3e9559";
const CACHE = `/var/cache/pacman/pkg/${FILE}`;
const COPY = `/var/lib/t2-bcm-firmware/${FILE}`;
const VAULT = "Personal";

async function verified(path: string) {
  if (!existsSync(path)) return false;
  const hasher = new Bun.CryptoHasher("sha256");
  hasher.update(await Bun.file(path).arrayBuffer());
  return hasher.digest("hex") === SHA256;
}

const installed = (pkg: string) => ok($`pacman -Q ${pkg}`);
const explicit = (pkg: string) => ok($`pacman -Qqe ${pkg}`);
const stateFilled = () => existsSync(STATE) && statSync(STATE).size > 0;
const fetched = async () => (await explicit(FETCHER)) && stateFilled();
const fallbackOk = async () => (await ok($`pacman -Qk ${PACKAGE}`)) && (await explicit(PACKAGE)) && (await verified(COPY));

/** The macOS volume's APFS container on the internal disk, as the fetcher looks for it. */
async function macosVolume() {
  const disks = (await $`lsblk -rno PATH,FSTYPE`.quiet().nothrow()).stdout.toString();
  return disks.split("\n").some((l) => {
    const [path, fstype] = l.split(" ");
    return path?.includes("nvme0n1") && fstype === "apfs";
  });
}

/**
 * brcmfmac read no firmware when it loaded; loading it again reads it now.
 * brcmfmac_wcc holds brcmfmac, so it goes first (as the fetcher's own reload
 * does); otherwise removing brcmfmac fails with "in use".
 */
async function reloadWifi() {
  await $`sudo modprobe -r brcmfmac_wcc`.quiet().nothrow();
  if (!((await ok($`sudo modprobe -r brcmfmac`)) && (await ok($`sudo modprobe brcmfmac`)))) {
    console.error("reboot for the Wi-Fi to pick up the firmware");
  }
}

async function fromMacos() {
  if (await installed(PACKAGE)) await $`sudo pacman -R --noconfirm ${PACKAGE}`;
  if (!(await installed(FETCHER))) await $`omarchy-pkg-add ${FETCHER}`;
  if (!(await explicit(FETCHER))) await $`sudo pacman -D --asexplicit ${FETCHER}`.quiet();
  // Its post-install fetches already when it can; run it until it has.
  if (!stateFilled()) await $`sudo ${FETCHER}`;
  await reloadWifi();
  if (!(await fetched())) throw new Error(`${FETCHER} didn't fetch the firmware from the macOS volume`);
}

async function fromFallback() {
  if (!(await verified(COPY))) {
    const tmp = await mkdtemp(`${tmpdir()}/t2-bcm-firmware-`);
    try {
      let source = CACHE;
      if (!(await verified(CACHE))) {
        console.error(`no macOS volume and no copy of ${FILE} here: from 1Password`);
        await opUnlocked("t2-bcm-firmware");
        source = `${tmp}/${FILE}`;
        await $`op document get ${FILE} --vault ${VAULT} --out-file ${source}`.quiet();
        if (!(await verified(source))) throw new Error(`the ${FILE} in 1Password doesn't match its SHA256`);
      }
      await $`sudo install -D -m 644 ${source} ${COPY}`;
    } finally {
      await rm(tmp, { recursive: true, force: true });
    }
  }
  if (!(await ok($`pacman -Qk ${PACKAGE}`))) {
    if (await installed(FETCHER)) await $`sudo pacman -R --noconfirm ${FETCHER}`;
    await $`sudo pacman -U --noconfirm ${COPY}`;
    await reloadWifi();
  }
  if (!(await explicit(PACKAGE))) await $`sudo pacman -D --asexplicit ${PACKAGE}`.quiet();
  if (!(await fallbackOk())) throw new Error(`${PACKAGE} isn't installed explicitly from ${COPY} after install`);
}

const done = async () => (await fetched()) || (await fallbackOk());

async function install() {
  if ((await fetched()) || (await fallbackOk())) return;
  if (await macosVolume()) await fromMacos();
  else await fromFallback();
}

await main(done, install);
