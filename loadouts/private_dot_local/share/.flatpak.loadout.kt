// flatpak: Flathub as a user-level remote (~/.local/share/flatpak), before any
// flatpak installs.
package loadouts

import loadout.dsl.*

/** Flathub as a user-level remote, so flatpaks can depend on it. */
val flathubRemote = program(
    name = "flathub-remote",
    description = "flathub flatpak remote (user)",
) {
    // A remote, not an app: the probe comes from flatpak, the rest is its own.
    installVia(
        flatpak {
            command = "flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
            present("flatpak --user remotes --columns=name | grep -x flathub")
        },
    )
}

val flatpakSetup = flatpak.requires(flathubRemote) // every flatpak needs the remote first
