#!/usr/bin/env bun
// Omarchy's firewall (ufw, incoming denied) vs T2 AirShare and t2-drop, which
// receive files from phones and Apple devices:
//   ufw allow 47901/tcp              Quick Share over the shared Wi-Fi network
//                                    (t2-airshare's receiver; the package fixes
//                                    the port, upstream takes any free one)
//   ufw allow in on t2qs0            the hotspot t2-quickshare-hotspot opens
//                                    for a transfer that started over Bluetooth:
//                                    the phone's DHCP and DNS (NetworkManager's
//                                    dnsmasq) and the transfer itself. The
//                                    helper opens its port only with firewalld.
//   ufw allow in on awdl0 to any port 8770 proto tcp
//                                    AirDrop's HTTPS on the AWDL interface
//                                    (t2-drop), IPv6 link-local
// Accepting still needs a yes in the notification (unless the sender is
// trusted). The check reads /etc/ufw/user.rules and user6.rules
// (world-readable) for the rules by their comments, so `loadout status`
// needs no sudo.
// Modes: `check` / `install` (default).
import { $, main, read } from "loadout/script";

const hex = (text: string) => Buffer.from(text).toString("hex");

// ufw records each rule as "### tuple ### <action> <proto> <dport> <dst> <sport>
// <src> <direction>[_<iface>] comment=<hex>".
const RULES: { file: string; pattern: string; tag: string; add: string[] }[] = [
  {
    file: "/etc/ufw/user.rules",
    tag: "t2-airshare quick share",
    pattern: "allow tcp 47901 \\S+ any \\S+ in",
    add: ["allow", "47901/tcp"],
  },
  {
    file: "/etc/ufw/user.rules",
    tag: "t2-airshare hotspot",
    pattern: "allow any any \\S+ any \\S+ in_t2qs0",
    add: ["allow", "in", "on", "t2qs0"],
  },
  {
    file: "/etc/ufw/user6.rules",
    tag: "t2-drop airdrop",
    pattern: "allow tcp 8770 \\S+ any \\S+ in_awdl0",
    add: ["allow", "in", "on", "awdl0", "to", "any", "port", "8770", "proto", "tcp"],
  },
];

const has = async (rule: (typeof RULES)[number]) =>
  new RegExp(`^### tuple ### ${rule.pattern} comment=${hex(rule.tag)}$`, "m").test(await read(rule.file));

async function ready() {
  for (const rule of RULES) if (!(await has(rule))) return false;
  return true;
}

async function install() {
  for (const rule of RULES) if (!(await has(rule))) await $`sudo ufw ${rule.add} comment ${rule.tag}`;
  if (!(await ready())) throw new Error("ufw rules for T2 AirShare and t2-drop not found in /etc/ufw after adding them");
}

await main(ready, install);
