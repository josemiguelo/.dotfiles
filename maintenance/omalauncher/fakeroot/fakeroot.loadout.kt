// fakeroot where the real one can't run (omalauncher's proot on Android).
package loadouts

import loadout.dsl.*

/** The proot shim as /usr/local/bin/fakeroot, so checkupdates (pacman's outdated oracle) runs. */
val fakerootShim = script(
    name = "fakeroot-shim",
    description = "a fakeroot that runs under proot, for checkupdates",
) {
    run("install -m 755 fakeroot /usr/local/bin/fakeroot")
    check("cmp -s fakeroot /usr/local/bin/fakeroot")
}
