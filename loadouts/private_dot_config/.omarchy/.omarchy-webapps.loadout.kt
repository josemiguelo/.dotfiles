package loadouts

import loadout.dsl.*

/** Omarchy web apps: `run(Webapps.remove, "Basecamp", "HEY")`. */
object Webapps {
    /** The web apps the machine names, removed the native way and kept removed across re-provisioning. */
    val remove = script(
        name = "omarchy-webapps-remove",
        description = "Omarchy web apps removed",
    ) {
        managedBy(".loadout/omarchy-webapps-remove.sh")
    }

    val gmail = script(
        name = "omarchy-webapp-gmail",
        description = "Gmail web app, the default for email links",
    ) {
        managedBy(".loadout/omarchy-webapp-gmail.sh")
        runAfter(remove) // HEY's launcher claims mailto too
    }

    val googleCalendar = script(
        name = "omarchy-webapp-google-calendar",
        description = "Google Calendar web app",
    ) {
        managedBy(".loadout/omarchy-webapp-google-calendar.sh")
    }

    val claude = script(
        name = "omarchy-webapp-claude",
        description = "Claude web app, on Hyper+C",
    ) {
        managedBy(".loadout/omarchy-webapp-claude.sh")
    }
}
