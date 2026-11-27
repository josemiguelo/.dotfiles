// Virtualization: KVM/QEMU with virt-manager, libvirt running for the login
// user, and ufw letting its default NAT network through.
import { program, script, withOmarchy } from "loadout";

// KVM/QEMU and virt-manager, one package each. dnsmasq is libvirt's
// NAT/DHCP; edk2-ovmf (UEFI) and swtpm (TPM, Windows 11) are optional deps.
export const libvirt = program("libvirt", {
  description: "libvirt virtualization daemon and tools",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

export const qemuDesktop = program("qemu-desktop", {
  description: "QEMU/KVM for desktop guests",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

export const virtManager = program("virt-manager", {
  description: "virt-manager GUI",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

export const virtInstall = program("virt-install", {
  description: "virt-install, command-line VM creation",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

export const virtViewer = program("virt-viewer", {
  description: "virt-viewer, a guest's graphical console",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

export const dnsmasq = program("dnsmasq", {
  description: "DNS/DHCP for libvirt's default NAT network",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

export const edk2Ovmf = program("edk2-ovmf", {
  description: "UEFI firmware for guests",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

export const swtpm = program("swtpm", {
  description: "TPM emulator for guests",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

// libvirt's optional DMI support: the host's SMBIOS for `virsh sysinfo` and
// guests' sysinfo; without it libvirtd logs "Cannot find 'dmidecode'" at start.
export const dmidecode = program("dmidecode", {
  description: "DMI table reader, libvirt's host system info",
  canWait: "VMs can wait; nothing in setup needs them",
  canBeInstalled: [withOmarchy],
});

export const archVirtualization = [libvirt, qemuDesktop, virtManager, virtInstall, virtViewer, dnsmasq, edk2Ovmf, swtpm, dmidecode];

// libvirtd running, the user in the right group, the default network
// autostarting.
export const setupLibvirt = script("setup-libvirt", {
  description: "libvirtd enabled and the login user in its group",
  canWait: "sets up the later virtualization programs",
  module: () => import("./.loadout/setup-libvirt.ts"),
  needsSudo: true,
  runAfter: [libvirt, qemuDesktop, dnsmasq],
});

// virbr0's DHCP/DNS and routed guest traffic, as commented rules the way
// Omarchy allows Docker's DNS.
export const ufwLibvirt = script("ufw-libvirt", {
  description: "ufw allows libvirt's default NAT network (virbr0)",
  canWait: "opens the firewall for the later virtualization programs",
  module: () => import("./.loadout/ufw-libvirt.ts"),
  needsSudo: true,
  runAfter: [setupLibvirt],
});
