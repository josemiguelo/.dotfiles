package loadouts

import loadout.dsl.*

val lunar = program(
    name = "lunar",
    description = "Lunar -- external display brightness/contrast control",
) {
    installVia(
        brewCask,
    )
}
