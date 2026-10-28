// The machine's name where loadout and chezmoi read it, in omalauncher's proot.
package loadouts

import loadout.dsl.*

/**
 * gethostname says "localhost" under proot and nothing can set it, so loadout
 * gets the name from LOADOUT_MACHINE (~/.bashrc) and chezmoi from
 * /etc/hostname. The first run passes --machine; this keeps it from then on.
 */
val machineName = script(
    name = "machine-name",
    description = "the machine's name in /etc/hostname and LOADOUT_MACHINE",
) {
    managedBy(".loadout/machine-name.sh")
}
