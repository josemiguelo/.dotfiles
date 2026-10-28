package loadouts

import loadout.dsl.*

val gh = program(
    name = "gh",
    description = "GitHub CLI",
) {
    installVia(
        brew,
        pacman(pkg = "github-cli"),
    )
}
