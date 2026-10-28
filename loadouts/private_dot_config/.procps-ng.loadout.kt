// procps-ng: ps, free and friends; Homebrew's Linux install needs it.
package loadouts

import loadout.dsl.*

val procpsNg = program(name = "procps-ng") {
    installVia(
        dnf,
        omarchy,
    )
}
