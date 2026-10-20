// fzf: the fuzzy finder. Its zsh side lives in zsh's conf.d/ and plugins/.
package repo

import loadout.dsl.*

val fzf = program(name = "fzf") {
    installVia(
        brew,
        dnf,
        omarchy,
    )
}
