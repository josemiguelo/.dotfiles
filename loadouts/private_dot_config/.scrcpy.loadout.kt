package loadouts

import loadout.dsl.*

val scrcpy = program(
    name = "scrcpy",
    description = "scrcpy Android screen mirroring",
) {
    installVia(
        brew,
        dnfCopr(copr = "zeno/scrcpy"),
    )
}
