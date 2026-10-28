package loadouts

import loadout.dsl.*

val jordanbairdIce = program(
    name = "jordanbaird-ice",
    description = "Ice -- menu bar icon organizer",
) {
    installVia(
        brewCask,
    )
}
