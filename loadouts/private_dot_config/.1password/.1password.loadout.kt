// 1Password: the app (its repo in .loadout/ on Fedora) and its CLI. Omarchy's
// setup of it is ../.omarchy's omarchy-1password.
package loadouts

import loadout.dsl.*

val onePassword = program(
    name = "1password",
    description = "1Password desktop app",
) {
    installVia(
        dnfRepo(repofile = file(".loadout/1password.repo")),
        // Omarchy's [omarchy] repo; omarchy-1password finishes the setup.
        omarchy,
    )
}

val onePasswordCli = program(
    name = "1password-cli",
    description = "1Password CLI (op)",
) {
    installVia(
        omarchy,
        brewCask,
    )
}
