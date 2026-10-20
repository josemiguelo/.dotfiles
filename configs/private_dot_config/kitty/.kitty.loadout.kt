// kitty: the terminal, the font its kitty.conf names, and (on Omarchy) kitty
// as the terminal everything opens.
package repo

import loadout.dsl.*

// Fedora: the solopasha COPR (fresher than the distro's); dnf-plugins-core
// now comes from the dnf-copr installer's `requires`. macOS: the cask, the
// same signed .dmg from kitty's GitHub releases.
val kitty = program(
    name = "kitty",
    description = "kitty terminal emulator",
) {
    installVia(
        dnfCopr(copr = "solopasha/kitty"),
        omarchy,
        brewCask,
    )
}

/** The family kitty.conf names (FiraCode Nerd Font Mono) on Linux. */
val ttfFiracodeNerd = program(
    name = "ttf-firacode-nerd",
    description = "FiraCode Nerd Font",
) {
    installVia(
        omarchy,
    )
}

val omarchyDefaultTerminal = script(
    name = "omarchy-default-terminal",
    description = "kitty as omarchy's default terminal",
) {
    managedBy(".loadout/default-terminal.sh")
    runAfter(kitty)
}
