// Base system tools other programs build on (Homebrew's Linux install needs
// all four). Config-less; a tool that gains a config moves beside it.
package loadouts

import loadout.dsl.*

val curl = program(name = "curl") {
    installVia(
        dnf,
        omarchy,
    )
}

val git = program(name = "git") {
    installVia(
        dnf,
        omarchy,
    )
}

val gcc = program(name = "gcc") {
    installVia(
        dnf,
        omarchy,
    )
}

val procpsNg = program(name = "procps-ng") {
    installVia(
        dnf,
        omarchy,
    )
}
