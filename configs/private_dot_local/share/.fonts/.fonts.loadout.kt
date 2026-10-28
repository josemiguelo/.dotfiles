package loadouts

import loadout.dsl.*

/** The FiraCode Nerd Fonts kitty.conf names, where no package carries them (macOS, Fedora). */
val downloadFonts = script(
    name = "download-fonts",
    description = "FiraCode nerd fonts",
) {
    managedBy(".loadout/download-fonts.sh")
}
