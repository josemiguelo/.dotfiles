// omalauncher: the launcher's files on this phone, kept in the repo as they
// are on the phone, and the packages they declare installed.
package loadouts

import loadout.dsl.*

/** Phone -> repo: new launcher files added, changed ones re-added, deleted ones forgotten (widgets' Claude hook runs it on every save). */
val omalauncherTracked = script(
    name = "omalauncher-tracked",
    description = "the launcher's files on this phone, as they are, in the repo",
) {
    managedBy(".loadout/tracked.sh")
    runAfter(chezmoi)
}

/** Home read again when the launcher left out widgets it read layout.toml too early to see (a new install's apply). */
val omalauncherLayout = script(
    name = "omalauncher-layout",
    description = "home as layout.toml says, once the widgets it names are there",
) {
    managedBy(".loadout/layout.sh")
    runAfter(chezmoi)
}

/** What the widgets' `requires { pacman: [...] }` declare: the files are the record, nothing else lists them. */
val omalauncherRequires = script(
    name = "omalauncher-requires",
    description = "every package the launcher's widgets declare",
) {
    managedBy(".loadout/requires.sh")
    needsSudo()
    runAfter(sudo, omalauncherTracked)
}
