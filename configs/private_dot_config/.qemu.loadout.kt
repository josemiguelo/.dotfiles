package loadouts

import loadout.dsl.*

val qemu = program(name = "qemu") {
    installVia(
        brew,
    )
}
