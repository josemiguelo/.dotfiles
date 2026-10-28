// gnu-sed: GNU's, for scripts written for it (macOS ships BSD tools).
package loadouts

import loadout.dsl.*

val gnuSed = program(name = "gnu-sed") {
    installVia(
        brew,
    )
}
