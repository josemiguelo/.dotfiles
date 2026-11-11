#!/usr/bin/env bun
// Omarchy's firewall (install/config/firewall.sh: ufw, incoming denied,
// forwarding DROP) vs libvirt's default NAT network on virbr0: guests would
// get no DHCP/DNS from the host's dnsmasq (incoming) and no way out through
// the NAT (routed). Omarchy's own pattern for Docker is explicit ufw allow
// rules with a comment; these follow it:
//   ufw allow in on virbr0            DHCP/DNS from guests to the host
//   ufw route allow in on virbr0      guests' traffic out through the NAT
//   ufw route allow out on virbr0     and the replies back in
// The check reads /etc/ufw/user.rules (world-readable) for the three rules
// by their comment, so `loadout status` needs no sudo for it.
// Modes: `check` / `install` (default).
import { $, main, read } from "#loadout";

const RULES = "/etc/ufw/user.rules";
const TAG = "libvirt";
const HEX = Buffer.from(TAG).toString("hex");

// ufw records each rule as "### tuple ### <action> … <direction>_<iface>
// comment=<hex>"; route rules carry a "route:" prefix on the action.
const has = async (action: string, direction: string) =>
  new RegExp(`^### tuple ### ${action} .* ${direction}_virbr0 comment=${HEX}$`, "m").test(await read(RULES));

const ready = async () => (await has("allow", "in")) && (await has("route:allow", "in")) && (await has("route:allow", "out"));

async function install() {
  if (!(await has("allow", "in"))) await $`sudo ufw allow in on virbr0 comment ${TAG}`;
  if (!(await has("route:allow", "in"))) await $`sudo ufw route allow in on virbr0 comment ${TAG}`;
  if (!(await has("route:allow", "out"))) await $`sudo ufw route allow out on virbr0 comment ${TAG}`;
  if (!(await ready())) throw new Error(`ufw rules for virbr0 not found in ${RULES} after adding them`);
}

await main(ready, install);
