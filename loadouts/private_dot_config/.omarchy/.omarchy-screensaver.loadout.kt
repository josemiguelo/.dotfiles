package loadouts

import loadout.dsl.*

/** The screensaver's branding text takes off as a flock of birds and lands back (cbirds, built with --hold), in place of ttfx's effects. */
val omarchyScreensaverBirds = script(
    name = "omarchy-screensaver-birds",
    description = "screensaver text flocks away as birds and lands back",
) {
    managedBy(".loadout/omarchy-screensaver-birds.sh")
    runAfter(gcc, git, setupGit, Overrides.commands)
}
