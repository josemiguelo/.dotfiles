package loadouts

import loadout.dsl.*

/** charmbracelet's gum (the dotfiles' gclone and workmux wrappers use it); an Omarchy base package. */
val gum = program(name = "gum") {
    installVia(
        brew,
        omarchy,
    )
}
