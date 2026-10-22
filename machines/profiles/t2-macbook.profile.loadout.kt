package repo

import loadout.dsl.*

/**
 * Every MacBookPro16,1 (T2) running Omarchy: the T2 hardware fixes and what
 * these machines run on top of Omarchy. Each install is its own machine
 * (named by its hostname, so each keeps its own state file).
 */
val t2Macbook = profile(name = "t2-macbook") {
    extends(omarchyProfile)

    install(t2fanrd)
    via(omarchy) {
        install(archVirtualization)
        install(solaar)
        install(rocmSmiLib) // btop's stats for the Radeon Pro 5300M/5500M
    }

    sshKey("id_ed25519")
    run(omarchySshd, "josemiguelo")

    run(T2.hidAppleKeyboard.variant(name = "arch"))
    run(T2.fanCurve, T2.fanGpuCard, T2.bootClock, T2.gmuxBacklight, T2.renderGpu)
    run(setupLibvirt.variant(name = "arch"), ufwLibvirt)
    run(Omarchy.sudolessDocker)
    run(Hyprland.activityMonitorSize, "90%", "90%")
    run(omarchyScratchpadOpacity, "0.99")
    run(solaarNoAutostart)
}
