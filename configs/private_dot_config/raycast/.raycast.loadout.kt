package loadouts

import loadout.dsl.*

/** The macOS launcher; its dotfiles are the script commands it runs. */
val raycast = program(
    name = "raycast",
    description = "Raycast launcher",
) {
    installVia(
        brewCask,
    )
}
