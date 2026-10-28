// coreutils: GNU's, for scripts written for it (macOS ships BSD tools).
package loadouts

import loadout.dsl.*

val coreutils = program(name = "coreutils") {
    installVia(
        brew,
    )
}
