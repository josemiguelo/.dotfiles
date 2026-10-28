// unixodbc: a library, not a tool; usql links against it.
package loadouts

import loadout.dsl.*

/** usql (a work repo's bootstrap-env.sh) links against it at a fixed path; without it usql dies with a dyld error. */
val unixodbc = program(name = "unixodbc") {
    installVia(
        brew,
    )
}
