// gcc: the C compiler builds need (Homebrew's Linux install).
package loadouts

import loadout.dsl.*

val gcc = program(name = "gcc") {
    installVia(
        dnf,
        omarchy,
    )
}
