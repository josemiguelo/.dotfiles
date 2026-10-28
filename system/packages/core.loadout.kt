// Base packages other programs build on (Homebrew's Linux install needs
// them and git).
package loadouts

import loadout.dsl.*

val curl = program(name = "curl") {
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
