// AnyDesk: its rpm on Fedora (.loadout/install-anydesk.sh), the AUR elsewhere.
package loadouts

import loadout.dsl.*

val anydesk = program(
    name = "anydesk",
    description = "AnyDesk remote desktop",
) {
    installVia(
        dnf {
            installedBy(".loadout/install-anydesk.sh")
            needsSudo()
        },
        // AnyDesk's own build; its unattended-access service is left disabled.
        omarchyAur(pkg = "anydesk-bin"),
    )
}
