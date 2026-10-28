package loadouts

import loadout.dsl.*

/** Linux (systemd user manager): the user environment matches ~/.config/environment.d. */
val userEnvironment = script(
    name = "user-environment",
    description = "systemd user environment matches ~/.config/environment.d",
) {
    managedBy(".loadout/user-environment.sh")
}
