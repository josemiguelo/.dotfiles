// zsh for omalauncher's Arch: its plugins as Arch packages, sourced by
// .zshrc; zsh itself and default-shell are ../zsh's.
package loadouts

import loadout.dsl.*

val zshAutosuggestions = program(name = "zsh-autosuggestions") {
    installVia(
        pacman,
    )
}

val zshSyntaxHighlighting = program(name = "zsh-syntax-highlighting") {
    installVia(
        pacman,
    )
}
