# libcrypt.so.1, which libxcrypt no longer ships (only .so.2): older runtime
# builds link it on Fedora, and Kotlin/Native's linuxX64 binaries on Arch
# (Intentional's core tests and desktop daemon don't start without it).

program "libxcrypt-compat" {
  install_via = [dnf, omarchy]
}
