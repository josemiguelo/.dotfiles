package loadouts

import loadout.dsl.*

val bat = program(name = "bat") {
    installVia(
        brew,
        omarchy,
        pacman,
    )
}
