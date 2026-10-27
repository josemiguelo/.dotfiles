package loadouts

import loadout.dsl.*

/**
 * The work MacBook. Its hostname is the one its IT gave it, so it names
 * itself in ~/.config/loadout/machine (bootstrap writes it, ~/.zshenv exports
 * it as LOADOUT_MACHINE); what only it has comes from the overlay.
 */
val workMac = machine(hostname = "work-mac") {
    extends(macos)
    data {
        work = true
    }
    run(workOverlay, ".dotfiles-work")
}
