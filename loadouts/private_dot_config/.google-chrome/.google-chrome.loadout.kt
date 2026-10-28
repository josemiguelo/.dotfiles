// Google Chrome: Google's rpm on Fedora (.loadout/install-chrome.sh).
package loadouts

import loadout.dsl.*

val googleChromeStable = program(
    name = "google-chrome-stable",
    description = "Google Chrome browser",
) {
    installVia(
        dnf {
            installedBy(".loadout/install-chrome.sh")
            needsSudo()
        },
    )
}
