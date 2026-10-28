// gawk: GNU's, for scripts written for it (macOS ships BSD tools).
package loadouts

import loadout.dsl.*

val gawk = program(name = "gawk") {
    installVia(
        brew,
    )
}
