package repo

import loadout.dsl.*

val solaar = program(
    name = "solaar",
    description = "Logitech device manager",
) {
    installVia(
        dnf {
            spare(reason = "for a Fedora machine; the fedora profile doesn't install solaar")
        },
        omarchy,
    )
}

/** Launched when wanted, not at every login. */
val solaarNoAutostart = script(
    name = "solaar-no-autostart",
    description = "remove solaar autostart entry",
) {
    run("sudo rm -f /etc/xdg/autostart/solaar.desktop")
    check("test ! -f /etc/xdg/autostart/solaar.desktop")
    runAfter(solaar)
}
