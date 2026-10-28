package loadouts

import loadout.dsl.*

val atuin = program(name = "atuin") {
    installVia(
        brew,
        omarchy,
    )
}
