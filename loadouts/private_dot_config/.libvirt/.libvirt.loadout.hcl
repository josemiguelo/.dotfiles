# Virtualization: KVM/QEMU with virt-manager, libvirt running for the login
# user, and ufw letting its default NAT network through.

# KVM/QEMU and virt-manager, one package each. dnsmasq is libvirt's
# NAT/DHCP; edk2-ovmf (UEFI) and swtpm (TPM, Windows 11) are optional deps.
program "libvirt" {
  description = "libvirt virtualization daemon and tools"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

program "qemu-desktop" {
  description = "QEMU/KVM for desktop guests"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

program "virt-manager" {
  description = "virt-manager GUI"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

program "virt-install" {
  description = "virt-install, command-line VM creation"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

program "virt-viewer" {
  description = "virt-viewer, a guest's graphical console"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

program "dnsmasq" {
  description = "DNS/DHCP for libvirt's default NAT network"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

program "edk2-ovmf" {
  description = "UEFI firmware for guests"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

program "swtpm" {
  description = "TPM emulator for guests"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

# libvirt's optional DMI support: the host's SMBIOS for `virsh sysinfo` and
# guests' sysinfo; without it libvirtd logs "Cannot find 'dmidecode'" at start.
program "dmidecode" {
  description = "DMI table reader, libvirt's host system info"
  later       = "VMs can wait; nothing in setup needs them"
  install_via = [omarchy]
}

locals {
  arch_virtualization = [
    program.libvirt,
    program.qemu-desktop,
    program.virt-manager,
    program.virt-install,
    program.virt-viewer,
    program.dnsmasq,
    program.edk2-ovmf,
    program.swtpm,
    program.dmidecode,
  ]
}

# libvirtd running, the user in the right group, the default network
# autostarting.
script "setup-libvirt" {
  description = "libvirtd enabled and the login user in its group"
  later       = "sets up the later virtualization programs"
  managed_by  = ".loadout/setup-libvirt.ts"
  needs_sudo  = true
  run_after   = [program.libvirt, program.qemu-desktop, program.dnsmasq]
}

# virbr0's DHCP/DNS and routed guest traffic, as commented rules the way
# Omarchy allows Docker's DNS.
script "ufw-libvirt" {
  description = "ufw allows libvirt's default NAT network (virbr0)"
  later       = "opens the firewall for the later virtualization programs"
  managed_by  = ".loadout/ufw-libvirt.ts"
  needs_sudo  = true
  run_after   = [script.setup-libvirt]
}
