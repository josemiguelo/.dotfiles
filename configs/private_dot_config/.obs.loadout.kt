package loadouts

import loadout.dsl.*

val obs = program(
    name = "obs",
    description = "OBS Studio -- screen recording/streaming",
) {
    installVia(
        brewCask,
    )
}
