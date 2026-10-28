package loadouts

import loadout.dsl.*

// Fedora's full vim is vim-enhanced (vim-minimal is the stub); Homebrew's
// formula is vim.
val vim = program(name = "vim") {
    installVia(
        dnf(pkg = "vim-enhanced"),
        brew,
    )
}
