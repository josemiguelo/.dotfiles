package loadouts

import loadout.dsl.*

val azureCli = program(
    name = "azure-cli",
    description = "Azure CLI",
) {
    installVia(
        brew,
    )
}
