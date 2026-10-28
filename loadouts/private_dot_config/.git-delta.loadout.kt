package loadouts

import loadout.dsl.*

val gitDelta = program(name = "git-delta") {
    installVia(
        brew,
        omarchy,
        pacman,
    )
}
