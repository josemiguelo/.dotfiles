package loadouts

import loadout.dsl.*

val ripgrep = program(name = "ripgrep") {
    installVia(
        brew,
        omarchy,
    )
}
