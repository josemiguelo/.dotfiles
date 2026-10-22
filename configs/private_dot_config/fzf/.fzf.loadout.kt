// fzf: the fuzzy finder. Its zsh side lives in zsh's conf.d/ and plugins/.
package loadouts

import loadout.dsl.*

val fzf = program(name = "fzf") {
    installVia(
        brew,
        dnf {
            spare(reason = "for a Fedora machine; the fedora profile doesn't install fzf")
        },
        omarchy,
    )
}
