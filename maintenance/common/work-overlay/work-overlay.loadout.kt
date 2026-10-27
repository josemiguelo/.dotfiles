// The work machine's overlay, from a private repo.
package loadouts

import loadout.dsl.*

/** What only the work machine has, from a private repo this one doesn't describe: `run(workOverlay, "<repo>")`. */
val workOverlay = script(
    name = "work-overlay",
    description = "the work machine's private overlay",
) {
    managedBy("work-overlay.sh")
    runAfter(git)
}
