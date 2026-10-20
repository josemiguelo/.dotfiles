package repo

import loadout.dsl.*

val ngrok = program(
    name = "ngrok",
    description = "ngrok tunnel",
) {
    custom {
        installedBy("install-ngrok.sh")
    }
    path("\$HOME/.local/bin")
    version(command = "ngrok version")
}
