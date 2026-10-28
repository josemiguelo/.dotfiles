package loadouts

import loadout.dsl.*

val treeSitterCli = program(name = "tree-sitter-cli") {
    installVia(
        brew,
        omarchy,
    )
}
