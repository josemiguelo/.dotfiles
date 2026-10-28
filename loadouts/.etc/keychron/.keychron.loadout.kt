package loadouts

import loadout.dsl.*

/** Keychron HID nodes open to the logged-in user (udev uaccess), so the Launcher (WebHID) connects. */
val keychronLauncherAccess = script(
    name = "keychron-launcher-access",
    description = "Keychron Launcher can reach the keyboard (WebHID)",
) {
    managedBy(".loadout/launcher-access.sh")
    needsSudo()
}
