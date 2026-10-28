package loadouts

import loadout.dsl.*

val jq = program(name = "jq") {
    installVia(
        brew,
    )
}
