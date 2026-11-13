// Virtualization: KVM/QEMU with virt-manager, libvirt running for the login
// user, and ufw letting its default NAT network through.
import { omarchy, program, script } from "loadout";

// KVM/QEMU and virt-manager, one package each. dnsmasq is libvirt's
// NAT/DHCP; edk2-ovmf (UEFI) and swtpm (TPM, Windows 11) are optional deps.
export const libvirt = program("libvirt", {
  description: "libvirt virtualization daemon and tools",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

export const qemuDesktop = program("qemu-desktop", {
  description: "QEMU/KVM for desktop guests",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

export const virtManager = program("virt-manager", {
  description: "virt-manager GUI",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

export const virtInstall = program("virt-install", {
  description: "virt-install, command-line VM creation",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

export const virtViewer = program("virt-viewer", {
  description: "virt-viewer, a guest's graphical console",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

export const dnsmasq = program("dnsmasq", {
  description: "DNS/DHCP for libvirt's default NAT network",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

export const edk2Ovmf = program("edk2-ovmf", {
  description: "UEFI firmware for guests",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

export const swtpm = program("swtpm", {
  description: "TPM emulator for guests",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

// libvirt's optional DMI support: the host's SMBIOS for `virsh sysinfo` and
// guests' sysinfo; without it libvirtd logs "Cannot find 'dmidecode'" at start.
export const dmidecode = program("dmidecode", {
  description: "DMI table reader, libvirt's host system info",
  later: "VMs can wait; nothing in setup needs them",
  install: [omarchy],
});

export const archVirtualization = [libvirt, qemuDesktop, virtManager, virtInstall, virtViewer, dnsmasq, edk2Ovmf, swtpm, dmidecode];

// libvirtd running, the user in the right group, the default network
// autostarting.
export const setupLibvirt = script("setup-libvirt", {
  description: "libvirtd enabled and the login user in its group",
  later: "sets up the later virtualization programs",
  managedBy: ".loadout/setup-libvirt.ts",
  needsSudo: true,
  runAfter: [libvirt, qemuDesktop, dnsmasq],
});

// virbr0's DHCP/DNS and routed guest traffic, as commented rules the way
// Omarchy allows Docker's DNS.
export const ufwLibvirt = script("ufw-libvirt", {
  description: "ufw allows libvirt's default NAT network (virbr0)",
  later: "opens the firewall for the later virtualization programs",
  managedBy: ".loadout/ufw-libvirt.ts",
  needsSudo: true,
  runAfter: [setupLibvirt],
});
