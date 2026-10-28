// Firefox: Mozilla's rpm on Fedora (.loadout/install-firefox.sh), and the
// flatpak gone.
package loadouts

import loadout.dsl.*

val firefox = program(
    name = "firefox",
    description = "Firefox browser",
) {
    installVia(
        dnf {
            installedBy(".loadout/install-firefox.sh")
            needsSudo()
        },
    )
}

/** The rpm firefox wins; the flatpak goes. */
val removeFirefoxFlatpak = script(
    name = "remove-firefox-flatpak",
    description = "remove the firefox flatpak",
) {
    run("flatpak --user uninstall --delete-data -y org.mozilla.firefox")
    check("! flatpak --user info org.mozilla.firefox >/dev/null 2>&1")
}
