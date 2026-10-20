package repo

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
