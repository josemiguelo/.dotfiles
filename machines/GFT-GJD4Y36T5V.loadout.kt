package loadouts

import loadout.dsl.*

/** The work MacBook. */
val workMac = machine(hostname = "GFT-GJD4Y36T5V") {
    extends(macos)
    data {
        zscaler = true
        work = true
    }
}
