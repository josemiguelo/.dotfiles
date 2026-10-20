// The Omarchy shell: plugins, the bar (position, widgets, icons, the menu
// button), the Pomodoro timer and Keystroke's Windows extension.
package repo

import loadout.dsl.*

/** The Omarchy shell and its bar: `run(OmarchyShell.bar, "top", "24")`. */
object OmarchyShell {
    /** Plugins from git, one URL per argument, each installed and enabled the Omarchy way; and whether each is behind its remote. */
    val plugins = script(
        name = "omarchy-plugins",
        description = "Omarchy shell plugins installed and enabled",
    ) {
        managedBy("omarchy-plugins.sh")
        updatesManagedBy("outdated-plugins.sh")
    }

    /** Position, thickness, and optionally a widget replacing the workspace numbers: `"top", "24", "<widget-id>"`. */
    val bar = script(
        name = "omarchy-bar",
        description = "Omarchy bar position, thickness, workspace widget and its settings",
    ) {
        managedBy("omarchy-bar.sh")
        runAfter(plugins)
    }

    /** Widgets with SVG icons, rebuilt from their source in the original's place (github.com/josemiguelo/omarchy-bar-icons). */
    val barIcons = script(
        name = "omarchy-bar-icons",
        description = "Bar widgets with SVG icons, rebuilt from their source",
    ) {
        managedBy("omarchy-bar-icons.sh")
        runAfter(plugins)
    }

    /** Where widgets sit: one argument per widget, `"<id> <left|right> <before|after> <neighbour-id>"`. */
    val barWidgets = script(
        name = "omarchy-bar-widgets",
        description = "Bar widgets' places and settings",
    ) {
        managedBy("omarchy-bar-widgets.sh")
        runAfter(plugins, barIcons)
    }

    val menuButton = script(
        name = "omarchy-menu-button",
        description = "The menu button in the place of Keystroke's bar button",
    ) {
        managedBy("omarchy-menu-button.sh")
        runAfter(plugins, barIcons)
    }

    val pomodoro = script(
        name = "omarchy-pomodoro",
        description = "Pomodoro timer: by the clock, 50+10, Trigger menu entries",
    ) {
        managedBy("omarchy-pomodoro.sh")
        runAfter(plugins, barIcons)
    }

    val keystrokeWindows = script(
        name = "omarchy-keystroke-windows",
        description = "Hyper+Space lists every window, by workspace (Keystroke)",
    ) {
        managedBy("omarchy-keystroke-windows.sh")
        runAfter(plugins)
    }
}

/** A typed argument for OmarchyShell.barWidgets: `widget("x").left.before("y")` reads as the bar does. */
class Widget(private val id: String) {
    private var section = ""
    val left get() = apply { section = "left" }
    val right get() = apply { section = "right" }
    fun before(neighbour: String) = "$id $section before $neighbour"
    fun after(neighbour: String) = "$id $section after $neighbour"
}

fun widget(id: String) = Widget(id)
