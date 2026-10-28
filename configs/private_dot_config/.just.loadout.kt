package loadouts

import loadout.dsl.*

val just = program(name = "just") {
    installVia(
        brew,
        dnf,
    )
}
