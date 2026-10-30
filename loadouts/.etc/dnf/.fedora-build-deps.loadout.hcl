# Fedora-only packages: the Development Tools group and the build libraries
# language-runtime builds need. Mapped by the fedora profile.

# A dnf group, not a package: its own install and a yes/no check.
program "development-tools-group" {
  description = "dnf Development Tools group"

  via "dnf" {
    command = "sudo dnf group install -y development-tools"
    present = "x=$(dnf group list --installed 2>/dev/null) && printf '%s\\n' \"$x\" | grep -q '^development-tools '"
  }
}

# One program per package, so each keeps its own version in state, diff and
# outdated; fedora_build_deps below keeps the profile to one line.
program "autoconf" {
  install_via = [dnf]
}

program "patch" {
  install_via = [dnf]
}

program "rust" {
  install_via = [dnf]
}

program "findutils" {
  install_via = [dnf]
}

program "bzip2-devel" {
  install_via = [dnf]
}

program "readline-devel" {
  install_via = [dnf]
}

program "sqlite" {
  install_via = [dnf]
}

program "sqlite-devel" {
  install_via = [dnf]
}

program "openssl-devel" {
  install_via = [dnf]
}

program "xz-devel" {
  install_via = [dnf]
}

program "libffi-devel" {
  install_via = [dnf]
}

program "tk-devel" {
  install_via = [dnf]
}

program "libzstd-devel" {
  install_via = [dnf]
}

program "libyaml-devel" {
  install_via = [dnf]
}

program "gdbm-devel" {
  install_via = [dnf]
}

program "ncurses-devel" {
  install_via = [dnf]
}

program "dbus-devel" {
  description = "D-Bus development headers"
  install_via = [dnf]
}

program "perl-FindBin" {
  install_via = [dnf]
}

program "libxcrypt-compat" {
  install_via = [dnf]
}

# A virtual provide on modern Fedora: the dnf variant with its own check.
program "zlib-devel" {
  via "dnf" { version = "rpm -q --whatprovides zlib-devel" }
}

# The build toolchain, as one list the fedora profile maps.
locals {
  fedora_build_deps = [
    program.development-tools-group,
    program.autoconf,
    program.patch,
    program.rust,
    program.findutils,
    program.zlib-devel,
    program.bzip2-devel,
    program.readline-devel,
    program.sqlite,
    program.sqlite-devel,
    program.openssl-devel,
    program.xz-devel,
    program.libffi-devel,
    program.tk-devel,
    program.libzstd-devel,
    program.libyaml-devel,
    program.gdbm-devel,
    program.ncurses-devel,
    program.dbus-devel,
    program.perl-FindBin,
    program.libxcrypt-compat,
  ]
}
