package loadouts

import loadout.dsl.*

/** wl-copy/wl-paste on the launcher's Wayland display, which hands copies to Android's clipboard (gh's one-time code, for one). */
val wlClipboard = program(name = "wl-clipboard") {
    installVia(
        pacman,
    )
}
