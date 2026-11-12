#!/usr/bin/env bun
// NetworkManager leaves the T2's internal USB network link alone.
//
// The T2 keeps the Mac's internal devices on a USB bus of its own, which the
// BCE driver (t2bce_vhci here, apple-bce on linux-t2) exposes as a virtual
// host. Beside the keyboard, trackpad and Touch Bar sits a CDC NCM network
// function, "Apple T2 Controller" (05ac:8233, MAC ac:de:48:00:11:22 on every
// T2 Mac): macOS's link to the T2 chip (iBridge), over IPv6 link-local.
// cdc_ncm binds it like any USB Ethernet adapter, NetworkManager makes a
// "Wired connection" for it, and since the T2 runs no DHCP server it retries
// every 45 s, forever. Nothing on Linux uses the link (KaiT2en's t2-airshare
// only keeps it out of mDNS).
//
// A udev rule tags it NM_UNMANAGED by its USB ID, not by driver: phones'
// USB tethering is cdc_ncm too, and t2-bcm-firmware's fallback needs it.
// Omarchy's installer (the fork's fix-t2.sh) writes the same rule to the same
// file, so the check asks what udev and NetworkManager do, not what the file
// says: on such an install this finds it working and writes nothing.
// Modes: `check` / `install` (default).
import { existsSync, readdirSync } from "node:fs";
import { $, main, out, readTrimmed, sudoWrite } from "#loadout";

const RULE = "/etc/udev/rules.d/90-t2-ibridge-unmanaged.rules";
const RULE_TEXT = `# Managed by loadout (t2-ibridge-unmanaged): NetworkManager leaves the T2's
# internal USB network link (Apple T2 Controller, 05ac:8233) alone. macOS talks
# to the T2 chip over it; Linux has no use for it, and with no DHCP server on
# the T2, NetworkManager would retry DHCP on it every 45 s.
SUBSYSTEM=="net", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="8233", ENV{NM_UNMANAGED}="1"
`;

/** The T2 link's interface, found by its USB device's IDs; none when it isn't there. */
async function linkInterface(): Promise<string | undefined> {
  for (const name of readdirSync("/sys/class/net")) {
    const usb = `/sys/class/net/${name}/device/..`;
    if ((await readTrimmed(`${usb}/idVendor`)) === "05ac" && (await readTrimmed(`${usb}/idProduct`)) === "8233") return name;
  }
}

/** udev tags it and NetworkManager has let go of it (state 10 is unmanaged). */
async function unmanaged(iface: string) {
  const props = (await out($`udevadm info --query=property /sys/class/net/${iface}`.nothrow())).split("\n");
  if (!props.includes("NM_UNMANAGED=1")) return false;
  const state = await out($`nmcli -g GENERAL.STATE device show ${iface}`.nothrow());
  return state.startsWith("10 ");
}

/** No link (the BCE driver isn't up) leaves only the rule to check. */
async function ready() {
  const iface = await linkInterface();
  if (iface) return unmanaged(iface);
  return existsSync(RULE);
}

async function install() {
  const iface = await linkInterface();
  if (iface && (await unmanaged(iface))) return;
  await sudoWrite(RULE, RULE_TEXT);
  await $`sudo udevadm control --reload`;
  if (iface) {
    // A change event re-runs the rules on the interface, so udev's database
    // has the tag now. NetworkManager reads NM_UNMANAGED only when a device
    // appears (1.58 ignores it on a change event), so the running one is told
    // directly; from the next boot the rule does it.
    await $`sudo udevadm trigger --action=change --settle /sys/class/net/${iface}`;
    await $`nmcli device set ${iface} managed no`;
    for (let i = 0; i < 20 && !(await unmanaged(iface)); i++) await Bun.sleep(250);
  }
  if (!(await ready())) throw new Error(`NetworkManager still manages ${iface} after ${RULE}`);
}

await main(ready, install);
