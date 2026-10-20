package repo

import loadout.dsl.*

/** MacBookPro16,1 (T2) running Omarchy. */
val t2MacbookOmarchy = machine(hostname = "t2-macbook-omarchy") {
    extends(t2Macbook)
}
