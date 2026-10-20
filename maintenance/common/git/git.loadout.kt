package repo

import loadout.dsl.*

/** Identity and delta as pager, written into ~/.gitconfig (not a chezmoi file). */
val setupGit = script(
    name = "setup-git",
    description = "git identity and delta configuration",
) {
    managedBy("setup-git.sh")
}
