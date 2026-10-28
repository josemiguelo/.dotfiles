// sudo where a rootfs ships without it (omalauncher's Arch): the built-in
// pacman installer runs `sudo pacman`, and loadout asks `sudo -n true` before
// any step that needs it. Root never needs a password.
package loadouts

import loadout.dsl.*

/**
 * Installed by root itself, since pacman's installer needs sudo already. A
 * script, not a command line: a command naming the package `sudo` reads as
 * one that runs sudo, and asks for it first.
 *
 * loadout asks for sudo before it installs anything, so on a fresh machine
 * `loadout install sudo` goes first, then `setup-new-machine`.
 */
val sudo = program(name = "sudo") {
    custom {
        installedBy("install-sudo.sh")
        needsSudo(false)
        // pacman's version, read the same way from its check and from
        // checkupdates (the pacman installer's oracle, which a custom variant
        // doesn't get), which prints it only when sudo is behind.
        version(command = "pacman -Q sudo", regex = """^sudo ([0-9][0-9.p]*[0-9])""")
        outdated = "checkupdates --nocolor | awk '\$1 == \"sudo\" {print \"sudo\", \$4}'"
    }
}

val pacmanSetup = pacman.requires(sudo) // every pacman install runs sudo

/** checkupdates, the pacman installer's outdated oracle: without it `loadout outdated` finds nothing there. */
val pacmanContrib = program(name = "pacman-contrib") {
    installVia(
        pacman,
    )
}
