package loadouts

import loadout.dsl.*

/** Samsung Galaxy A56 5G (SM-A566E) running Arch in omalauncher. */
val omalauncherGalaxyA56 = machine(hostname = "omalauncher-galaxy-a56") {
    extends(omalauncherProfile)
}
