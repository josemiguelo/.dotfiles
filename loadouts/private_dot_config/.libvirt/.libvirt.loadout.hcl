# Virtualization: KVM/QEMU with virt-manager, libvirt running for the login
# user, and ufw letting its default NAT network through.

# Arch: what Fedora's "virtualization" group installed, one package each.
# dnsmasq is libvirt's NAT/DHCP; edk2-ovmf (UEFI) and swtpm (TPM, Windows
# 11) are optional deps the Fedora group installed too.
program "libvirt" {
  description = "libvirt virtualization daemon and tools"
  install_via = [omarchy]
}

program "qemu-desktop" {
  description = "QEMU/KVM for desktop guests"
  install_via = [omarchy]
}

program "virt-manager" {
  description = "virt-manager GUI"
  install_via = [omarchy]
}

program "virt-install" {
  description = "virt-install, command-line VM creation"
  install_via = [omarchy]
}

program "virt-viewer" {
  description = "virt-viewer, a guest's graphical console"
  install_via = [omarchy]
}

program "dnsmasq" {
  description = "DNS/DHCP for libvirt's default NAT network"
  install_via = [omarchy]
}

program "edk2-ovmf" {
  description = "UEFI firmware for guests"
  install_via = [omarchy]
}

program "swtpm" {
  description = "TPM emulator for guests"
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
  ]
}

# Fedora: the virtualization dnf group; the two-mode script is its check. No
# profile maps it today (the compile lists it).
program "virtualization" {
  description = "virtualization stack (libvirt, qemu, virt-manager)"
  spare       = "Fedora's half of setup-libvirt; no machine runs Fedora today"
  via "dnf" {
    managed_by = ".loadout/virtualization.sh"
    needs_sudo = true
  }
}

# libvirtd running, the user in the right group, the default network
# autostarting; Arch and Fedora do it differently.
script "setup-libvirt" {
  description = "libvirtd enabled and the login user in its group"
  needs_sudo  = true

  variant "arch" {
    managed_by = ".loadout/setup-libvirt-arch.sh"
    run_after  = [program.libvirt, program.qemu-desktop, program.dnsmasq]
  }

  # The source script ran usermod as root ($(whoami) bug); this is the
  # login user, as intended.
  variant "fedora" {
    spare = "no machine runs Fedora today"
    run = [
      "sudo systemctl enable libvirtd",
      "sudo systemctl start libvirtd",
      "sudo usermod -a -G kvm \"$USER\"",
    ]
    check = [
      "systemctl is-enabled libvirtd >/dev/null 2>&1",
      "id -nG \"$USER\" | grep -qw kvm",
    ]
    run_after = [program.virtualization]
  }
}

# virbr0's DHCP/DNS and routed guest traffic, as commented rules the way
# Omarchy allows Docker's DNS.
script "ufw-libvirt" {
  description = "ufw allows libvirt's default NAT network (virbr0)"
  managed_by  = ".loadout/ufw-libvirt.sh"
  needs_sudo  = true
  run_after   = [script.setup-libvirt]
}
