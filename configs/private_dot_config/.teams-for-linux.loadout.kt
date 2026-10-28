package loadouts

import loadout.dsl.*

val teamsForLinux = program(
    name = "teams-for-linux",
    description = "Microsoft Teams client",
) {
    installVia(
        dnfRepo(repofile = "https://repo.teamsforlinux.de/rpm/teams-for-linux.repo"),
        omarchyAur(pkg = "teams-for-linux-bin"), // the source package rebuilds Electron
    )
}
