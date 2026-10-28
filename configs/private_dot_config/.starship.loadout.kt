// starship: the prompt. Its config is starship.toml, beside this file.
package loadouts

import loadout.dsl.*

/** The shell prompt; its config is configs/private_dot_config/starship.toml, one file among others'. */
val starship = program(name = "starship") {
    installVia(
        brew,
        omarchy,
    )
}
