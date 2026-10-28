package loadouts

import loadout.dsl.*

val jiraCli = program(
    name = "jira-cli",
    description = "Jira CLI",
) {
    installVia(
        brew,
    )
}
