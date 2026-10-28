package loadouts

import loadout.dsl.*

val vlc = program(
    name = "vlc",
    description = "VLC media player",
) {
    installVia(
        dnf,
        omarchy,
    )
}
