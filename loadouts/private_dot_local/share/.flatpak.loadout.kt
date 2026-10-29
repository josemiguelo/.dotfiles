// flatpak: the package itself and Flathub as a user-level remote
// (~/.local/share/flatpak). Every flatpak install `requires` both, so they
// come first.
package loadouts

import loadout.dsl.*

/** Fedora ships it; Omarchy doesn't. */
val flatpakPackage = program(
    name = "flatpak",
    description = "flatpak app runtime",
) {
    // So a plan installing it may install flatpaks after it.
    installVia(
        dnf { provides("flatpak") },
        omarchy { provides("flatpak") },
    )
}

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
            dependsOn(flatpakPackage) // a flatpak variant itself, so exempt from the rule below
        },
    )
}

val flatpakSetup = run {
    flatpak.requires(flatpakPackage, flathubRemote)
}
