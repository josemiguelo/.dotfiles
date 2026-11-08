# Testing Omarchy ISOs (omacom/omarchy-iso's bin/omarchy-iso-test), including
# on hardware the VM doesn't have: `--fake-pci` (an Apple T2 is
# 106b:1802:088000) runs libvfio-user's gpio-pci-idio-16 sample as the fake
# device's vfio-user server. Arch doesn't package the library, so it's built
# from a clone (omarchy-iso's test/fake-pci.md):
#   meson setup build -Ddefault_library=static && ninja -C build samples/gpio-pci-idio-16

# One program per package, so each keeps its own version in state, diff and
# outdated; omarchy_iso_test_deps below keeps the machine to one line.

# The harness installs qemu-full itself on every run (omarchy-pkg-add, which
# needs a sudo prompt), so it's declared here rather than left to that.
program "qemu-full" {
  description = "QEMU with every component (what omarchy-iso-test asks for)"
  install_via = [omarchy]
}

# libvfio-user's build deps.
program "meson" {
  install_via = [omarchy]
}

program "ninja" {
  install_via = [omarchy]
}

program "json-c" {
  install_via = [omarchy]
}

program "cmocka" {
  install_via = [omarchy]
}

locals {
  omarchy_iso_test_deps = [
    program.qemu-full,
    program.meson,
    program.ninja,
    program.json-c,
    program.cmocka,
  ]
}
