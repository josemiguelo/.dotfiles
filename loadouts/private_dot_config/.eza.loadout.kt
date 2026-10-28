package loadouts

import loadout.dsl.*

val eza = program(name = "eza") {
    installVia(
        brew,
        omarchy,
        pacman,
    )
}
