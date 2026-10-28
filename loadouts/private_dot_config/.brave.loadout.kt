package loadouts

import loadout.dsl.*

// The AUR's brave-bin (Brave's own build, repackaged), what Omarchy's
// `omarchy install browser brave` adds. The omarchy-brave script runs that
// installer for Omarchy's policy, flags and theme.
val brave = program(
    name = "brave",
    description = "Brave browser",
) {
    installVia(
        omarchyAur(pkg = "brave-bin"),
    )
}
