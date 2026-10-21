// Virtualization: KVM/QEMU with virt-manager, libvirt running for the login
// user, and ufw letting its default NAT network through.
package repo

import loadout.dsl.*

// Arch: what Fedora's "virtualization" group installed, one package each.
// dnsmasq is libvirt's NAT/DHCP; edk2-ovmf (UEFI) and swtpm (TPM, Windows
// 11) are optional deps the Fedora group installed too.
val libvirt = program(
    name = "libvirt",
    description = "libvirt virtualization daemon and tools",
) {
    installVia(
        omarchy,
    )
}

val qemuDesktop = program(
    name = "qemu-desktop",
    description = "QEMU/KVM for desktop guests",
) {
    installVia(
        omarchy,
    )
}

val virtManager = program(
    name = "virt-manager",
    description = "virt-manager GUI",
) {
    installVia(
        omarchy,
    )
}

val virtInstall = program(
    name = "virt-install",
    description = "virt-install, command-line VM creation",
) {
    installVia(
        omarchy,
    )
}

val virtViewer = program(
    name = "virt-viewer",
    description = "virt-viewer, a guest's graphical console",
) {
    installVia(
        omarchy,
    )
}

val dnsmasq = program(
    name = "dnsmasq",
    description = "DNS/DHCP for libvirt's default NAT network",
) {
    installVia(
        omarchy,
    )
}

val edk2Ovmf = program(
    name = "edk2-ovmf",
    description = "UEFI firmware for guests",
) {
    installVia(
        omarchy,
    )
}

val swtpm = program(
    name = "swtpm",
    description = "TPM emulator for guests",
) {
    installVia(
        omarchy,
    )
}

val archVirtualization = listOf(libvirt, qemuDesktop, virtManager, virtInstall, virtViewer, dnsmasq, edk2Ovmf, swtpm)

/** Fedora: the virtualization dnf group; the two-mode script is its check. No profile maps it today (the compile lists it). */
val virtualization = program(
    name = "virtualization",
    description = "virtualization stack (libvirt, qemu, virt-manager)",
) {
    spare(reason = "Fedora's half of setup-libvirt; no machine runs Fedora today")
    installVia(
        dnf {
            managedBy("virtualization.sh")
        },
    )
}

// libvirtd running, the user in the right group, the default network
// autostarting; Arch and Fedora do it differently.
val setupLibvirt = script(
    name = "setup-libvirt",
    description = "libvirtd enabled and the login user in its group",
) {
    needsSudo()
    variant(name = "arch") {
        managedBy("setup-libvirt-arch.sh")
        runAfter(libvirt, qemuDesktop, dnsmasq)
    }
    // The source script ran usermod as root ($(whoami) bug); this is the
    // login user, as intended.
    variant(name = "fedora") {
        spare(reason = "no machine runs Fedora today")
        run(
            "sudo systemctl enable libvirtd",
            "sudo systemctl start libvirtd",
            "sudo usermod -a -G kvm \"$USER\"",
        )
        check(
            "systemctl is-enabled libvirtd >/dev/null 2>&1",
            "id -nG \"$USER\" | grep -qw kvm",
        )
        runAfter(virtualization)
    }
}

/** virbr0's DHCP/DNS and routed guest traffic, as commented rules the way Omarchy allows Docker's DNS. */
val ufwLibvirt = script(
    name = "ufw-libvirt",
    description = "ufw allows libvirt's default NAT network (virbr0)",
) {
    managedBy("ufw-libvirt.sh")
    needsSudo()
    runAfter(setupLibvirt)
}
