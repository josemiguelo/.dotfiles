package loadouts

import loadout.dsl.*

val meetingbar = program(
    name = "meetingbar",
    description = "MeetingBar -- calendar meetings in the menu bar",
) {
    installVia(
        brewCask,
    )
}
