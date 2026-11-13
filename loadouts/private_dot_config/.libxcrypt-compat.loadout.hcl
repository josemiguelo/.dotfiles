# libcrypt.so.1, which libxcrypt no longer ships (only .so.2): Kotlin/Native's
# linuxX64 binaries link it (Intentional's core tests and desktop daemon don't start without it).

program "libxcrypt-compat" {
  install_via = [omarchy]
}
