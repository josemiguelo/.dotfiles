package loadouts

import loadout.dsl.*

val trashCli = program(name = "trash-cli") {
    installVia(
        brew,
        pacman,
    )
}
