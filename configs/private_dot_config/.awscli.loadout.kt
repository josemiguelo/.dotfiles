package loadouts

import loadout.dsl.*

val awscli = program(name = "awscli") {
    installVia(
        brew,
    )
}
