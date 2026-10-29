// stremio: the media center, from Flathub.
package loadouts

import loadout.dsl.*

val stremio = program(
    name = "stremio",
    description = "Stremio media center",
) {
    installVia(
        flatpak(pkg = "com.stremio.Stremio"),
    )
}
