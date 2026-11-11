#!/usr/bin/env bun
// libvirt on Arch, ready for virt-manager on qemu:///system without root:
//   - libvirtd.service enabled and running (the monolithic daemon, as on
//     Fedora; it also autostarts guests marked to autostart)
//   - the login user in Arch's `libvirt` group, which libvirt's polkit rule
//     lets manage the system connection (takes effect at the next login)
//   - the `default` NAT network started and set to autostart
// Checks read only what a user can see without sudo: the service and the
// group. The network is set up by install, idempotently.
// Modes: `check` / `install` (default).
import { userInfo } from "node:os";
import { $, main, ok } from "#loadout";

const USER = process.env.USER || userInfo().username;

const inGroup = async () => {
  const entry = (await $`getent group libvirt`.quiet().nothrow()).stdout.toString().trim();
  return (entry.split(":")[3] ?? "").split(",").includes(USER);
};

/** `virsh net-info default`, read with sudo ("" when it fails). */
const netInfo = async () => (await $`sudo virsh -c qemu:///system net-info default`.quiet().nothrow()).stdout.toString();

await main(
  async () =>
    (await ok($`systemctl -q is-enabled libvirtd.service`)) &&
    (await ok($`systemctl -q is-active libvirtd.service`)) &&
    (await inGroup()),
  async () => {
    await $`sudo systemctl enable --now libvirtd.service`;
    if (!(await inGroup())) {
      await $`sudo usermod -aG libvirt ${USER}`;
      console.log(`added ${USER} to libvirt — takes effect at the next login`);
    }
    if (!/^Autostart:\s*yes/m.test(await netInfo())) await $`sudo virsh -c qemu:///system net-autostart default`;
    if (!/^Active:\s*yes/m.test(await netInfo())) await $`sudo virsh -c qemu:///system net-start default`;
    await $`sudo virsh -c qemu:///system net-list --all`;
  },
);
