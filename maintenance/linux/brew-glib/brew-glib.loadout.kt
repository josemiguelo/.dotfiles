package repo

import loadout.dsl.*

/** Linux: brew's glib unlinked, so the system's gsettings, gio and gdbus are the ones on PATH. */
val unlinkBrewGlib = script(
    name = "unlink-brew-glib",
    description = "brew's glib unlinked (the system's gsettings reaches dconf)",
) {
    managedBy("unlink-brew-glib.sh")
}
