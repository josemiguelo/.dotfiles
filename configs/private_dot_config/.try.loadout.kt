package loadouts

import loadout.dsl.*

val tryCli = program(
    name = "try",
    description = "ephemeral workspace manager",
) {
    installVia(
        brew,
    )
}
