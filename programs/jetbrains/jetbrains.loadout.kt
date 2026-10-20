// JetBrains: the Toolbox app and its launchers on PATH. The IdeaVim config
// is a single file in ~ (configs/dot_ideavimrc), so this lives here.
package repo

import loadout.dsl.*

val jetbrainsToolbox = program(
    name = "jetbrains-toolbox",
    description = "JetBrains Toolbox",
) {
    // Linux: per-user install from JetBrains' release feed (the script says
    // why not the ublue-os cask). Version = the build.txt Toolbox ships.
    custom(name = "linux") {
        managedBy("install-toolbox.sh", version = VERSION)
    }

    // macOS: the cask. No machine installs it yet.
    installVia(
        brewCask,
    )
}

val linkJetbrainsLaunchers = script(
    name = "link-jetbrains-launchers-linux",
    description = "symlink JetBrains Toolbox launcher scripts into ~/.local/bin",
) {
    managedBy("link-launchers.sh")
    runAfter(jetbrainsToolbox)
}
