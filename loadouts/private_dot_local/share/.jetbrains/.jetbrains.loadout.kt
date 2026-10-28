// JetBrains: the Toolbox app (it installs into ~/.local/share/JetBrains) and
// its launchers on PATH. IdeaVim's config is loadouts/dot_ideavimrc.
package loadouts

import loadout.dsl.*

val jetbrainsToolbox = program(
    name = "jetbrains-toolbox",
    description = "JetBrains Toolbox",
) {
    // Linux: per-user install from JetBrains' release feed (the script says
    // why not the ublue-os cask). Version = the build.txt Toolbox ships.
    custom(name = "linux") {
        managedBy(".loadout/install-toolbox.sh", version = VERSION)
    }

    installVia(
        brewCask {
            spare(reason = "for macOS; no Mac installs it yet")
        },
    )
}

val linkJetbrainsLaunchers = script(
    name = "link-jetbrains-launchers-linux",
    description = "symlink JetBrains Toolbox launcher scripts into ~/.local/bin",
) {
    managedBy(".loadout/link-launchers.sh")
    runAfter(jetbrainsToolbox)
}
