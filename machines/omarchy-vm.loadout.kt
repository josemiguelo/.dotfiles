package loadouts

import loadout.dsl.*

/** A libvirt VM for testing a new-machine setup end to end: plain Omarchy, no T2 hardware, plus the ssh key. */
val omarchyVm = machine(hostname = "omarchy-vm") {
    extends(omarchyProfile)
    sshKey("id_ed25519")
}
