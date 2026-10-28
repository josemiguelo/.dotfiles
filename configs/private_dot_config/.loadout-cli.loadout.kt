package loadouts

import loadout.dsl.*

/** Its release, into ~/.local; `loadout sync` and `self-upgrade` keep it current. */
val loadoutCli = program(
    name = "loadout",
    description = "loadout, which reads this repo",
) {
    custom {
        command = "curl -fsSL https://raw.githubusercontent.com/josemiguelo/loadout/master/install.sh | sh"
    }

    path("$HOME/.local/bin")
    version(command = "loadout --version")
}
