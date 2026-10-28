package loadouts

import loadout.dsl.*

val zoxide = program(name = "zoxide") {
    installVia(
        brew,
        omarchy,
        pacman,
    )
}
