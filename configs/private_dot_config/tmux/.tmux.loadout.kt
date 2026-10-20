// tmux: the multiplexer, its plugin manager and plugins, and (on Omarchy)
// keeping kitty's palette across theme switches.
package repo

import loadout.dsl.*

/** On Omarchy a base package, mapped to Omarchy's installer so workmux resolves it without brew installing a second copy. */
val tmux = program(name = "tmux") {
    installVia(
        brew,
        dnf,
        omarchy,
    )
}

val tpack = program(
    name = "tpack",
    description = "tmux package manager",
) {
    // macOS: a cask from its tap.
    installVia(
        tapCask(tap = "tmuxpack/tpack"),
    )

    // Linux: its GitHub release, since the cask pulls in brew's tmux and git,
    // which would shadow the system's. Its own copy only: a tpack on PATH may
    // still be the cask's, which remove-brew-tmux takes away after this.
    custom(name = "linux") {
        installedBy(".loadout/install-tpack.sh")
        version(command = "\$HOME/.local/bin/tpack --version")
    }
}

/** The plugins tmux.conf declares, present as clones; and whether each clone is behind its GitHub tip. */
val tmuxPlugins = script(
    name = "tmux-plugins",
    description = "tmux plugins tmux.conf declares",
) {
    managedBy(".loadout/plugins.sh")
    runAfter(tmux, tpack)
    updatesManagedBy(".loadout/outdated-plugins.sh")
}

/** Linux: brew's tpack cask gone, with the tmux and git it pulled in. */
val removeBrewTmux = script(
    name = "remove-brew-tmux",
    description = "no tpack, tmux or git from brew (Linux has its own)",
) {
    managedBy(".loadout/remove-brew-tmux.sh")
    runAfter(tpack)
}

/** Undoes omarchy-theme-set-tmux after each theme switch: tmux here follows kitty's palette. */
val omarchyTmuxTheme = script(
    name = "omarchy-tmux-theme",
    description = "tmux keeps kitty's palette across omarchy theme switches",
) {
    managedBy(".loadout/omarchy-theme.sh")
    runAfter(tmux)
}
