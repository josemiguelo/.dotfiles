package loadouts

import loadout.dsl.*

val lazydocker = program(name = "lazydocker") {
    installVia(
        brew,
        omarchy,
    )
}
