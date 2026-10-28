// curl: downloads in install commands, and Homebrew's Linux install needs it.
package loadouts

import loadout.dsl.*

val curl = program(name = "curl") {
    installVia(
        dnf,
        omarchy,
    )
}
