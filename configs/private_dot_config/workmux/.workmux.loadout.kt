package loadouts

import loadout.dsl.*

/** From its author's tap. */
val workmux = program(
    name = "workmux",
    description = "git worktrees + tmux windows for parallel agent sessions",
) {
    dependsOn(tmux)
    installVia(
        tap(tap = "raine/workmux"),
    )
}

/** Reruns after every workmux upgrade, since one can change the hooks or skills. */
val workmuxSetup = script(
    name = "workmux-setup",
    description = "workmux's status-tracking hooks and skills for the agents here",
) {
    managedBy(".loadout/setup.sh")
    runAfter(workmux)
}
