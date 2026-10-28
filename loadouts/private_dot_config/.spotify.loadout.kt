// spotify: the music app. Its Omarchy launch flags are spotify-flags.conf,
// beside this file.
package loadouts

import loadout.dsl.*

val spotify = program(
    name = "spotify",
    description = "Spotify music streaming",
) {
    installVia(
        omarchy, // Omarchy's own repo carries it
        brewCask {
            spare(reason = "for macOS; no Mac installs it yet")
        },
    )
}
