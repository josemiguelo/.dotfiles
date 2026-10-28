package loadouts

import loadout.dsl.*

val fd = program(name = "fd") {
    installVia(
        brew,
        omarchy,
    )
}
