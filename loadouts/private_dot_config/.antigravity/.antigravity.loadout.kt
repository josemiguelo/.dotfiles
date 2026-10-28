// Antigravity: Google's repo on Fedora (.loadout/antigravity.repo), the AUR
// elsewhere.
package loadouts

import loadout.dsl.*

val antigravity = program(
    name = "antigravity",
    description = "Antigravity IDE",
) {
    installVia(
        dnfRepo(repofile = file(".loadout/antigravity.repo")),
        // Google's IDE tarball, repackaged; not the AUR's `antigravity` (2.0, a
        // different product).
        omarchyAur(pkg = "antigravity-ide"),
    )
}
