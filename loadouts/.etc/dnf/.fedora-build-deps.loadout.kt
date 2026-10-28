// Fedora-only packages: the Development Tools group and the build libraries
// language-runtime builds need. Mapped by the fedora profile.
package loadouts

import loadout.dsl.*

// A dnf group, not a package: its own install and a yes/no check.
val developmentToolsGroup = program(
    name = "development-tools-group",
    description = "dnf Development Tools group",
) {
    installVia(
        dnf {
            command = "sudo dnf group install -y development-tools"
            present("dnf group list --installed 2>/dev/null | grep '^development-tools '")
        },
    )
}

// One program per package, so each keeps its own version in state, diff and
// outdated; fedoraBuildDeps below keeps the profile to one line.
val autoconf = program(name = "autoconf") {
    installVia(
        dnf,
    )
}

val patch = program(name = "patch") {
    installVia(
        dnf,
    )
}

val rust = program(name = "rust") {
    installVia(
        dnf,
    )
}

val findutils = program(name = "findutils") {
    installVia(
        dnf,
    )
}

val bzip2Devel = program(name = "bzip2-devel") {
    installVia(
        dnf,
    )
}

val readlineDevel = program(name = "readline-devel") {
    installVia(
        dnf,
    )
}

val sqlite = program(name = "sqlite") {
    installVia(
        dnf,
    )
}

val sqliteDevel = program(name = "sqlite-devel") {
    installVia(
        dnf,
    )
}

val opensslDevel = program(name = "openssl-devel") {
    installVia(
        dnf,
    )
}

val xzDevel = program(name = "xz-devel") {
    installVia(
        dnf,
    )
}

val libffiDevel = program(name = "libffi-devel") {
    installVia(
        dnf,
    )
}

val tkDevel = program(name = "tk-devel") {
    installVia(
        dnf,
    )
}

val libzstdDevel = program(name = "libzstd-devel") {
    installVia(
        dnf,
    )
}

val libyamlDevel = program(name = "libyaml-devel") {
    installVia(
        dnf,
    )
}

val gdbmDevel = program(name = "gdbm-devel") {
    installVia(
        dnf,
    )
}

val ncursesDevel = program(name = "ncurses-devel") {
    installVia(
        dnf,
    )
}

val dbusDevel = program(
    name = "dbus-devel",
    description = "D-Bus development headers",
) {
    installVia(
        dnf,
    )
}

val perlFindBin = program(name = "perl-FindBin") {
    installVia(
        dnf,
    )
}

val libxcryptCompat = program(name = "libxcrypt-compat") {
    installVia(
        dnf,
    )
}

// A virtual provide on modern Fedora: the dnf variant with its own check.
val zlibDevel = program(name = "zlib-devel") {
    installVia(
        dnf {
            version(command = "rpm -q --whatprovides zlib-devel")
        },
    )
}

/** The build toolchain, as one list the fedora profile maps. */
val fedoraBuildDeps = listOf(
    developmentToolsGroup, autoconf, patch, rust, findutils, zlibDevel,
    bzip2Devel, readlineDevel, sqlite, sqliteDevel, opensslDevel, xzDevel,
    libffiDevel, tkDevel, libzstdDevel, libyamlDevel, gdbmDevel,
    ncursesDevel, dbusDevel, perlFindBin, libxcryptCompat,
)
