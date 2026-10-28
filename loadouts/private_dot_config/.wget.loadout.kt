package loadouts

import loadout.dsl.*

val wget = program(name = "wget") {
    installVia(
        brew,
    )
}
