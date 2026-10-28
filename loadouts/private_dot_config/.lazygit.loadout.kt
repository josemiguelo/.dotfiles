package loadouts

import loadout.dsl.*

val lazygit = program(name = "lazygit") {
    installVia(
        brew,
        omarchy,
    )
}
