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

/**
 * The bar this repo's Omarchy machines share: its plugins, which icons it
 * shows and where the widgets sit. A profile calls `omarchyBar()`, so the
 * settings live beside the scripts that apply them.
 */
fun MachineScope.omarchyBar() {
    run(OmarchyShell.bar, "top", "24", "tornikegomareli.spaces")
    run(
        OmarchyShell.plugins,
        "https://github.com/evindor/keystroke.git",
        "https://github.com/jankeesvw/omarchy-notification-center.git",
        "https://github.com/tornikegomareli/omarchy-spaces.git",
        "https://github.com/binoymanoj/pomodoro-omarchy.git",
        "https://github.com/Zeus-Deus/voxtype-omarchy-plugin.git",
        "https://github.com/sumdahl/omarchy-plugin-media.git",
    )
    run(
        OmarchyShell.barIcons,
        "josemiguelo.menu-button", "josemiguelo.workspace-layout", "josemiguelo.theme-mode",
        "omarchy.monitor", "omarchy.bluetooth", "omarchy.network", "omarchy.audio",
        "omarchy.power", "omarchy.agents", "omarchy.system-update", "omarchy.indicators",
        "omarchy.weather", "omarchy.tray",
        "jankeesvw.notification-center", "io.github.zeus-deus.voxtype", "io.github.sumdahl.media",
        "pomodoro-omarchy", "omarchy.clock", "tornikegomareli.spaces",
    )
    run(
        OmarchyShell.barWidgets,
        widget("josemiguelo.workspace-layout").left.before("tornikegomareli.spaces"),
        widget("josemiguelo.menu-button").left.before("josemiguelo.workspace-layout"),
        widget("io.github.sumdahl.media").right.after("omarchy.tray"),
        widget("omarchy.power").right.after("omarchy.monitor"),
        widget("josemiguelo.theme-mode").right.before("omarchy.tray"),
    )
    run(OmarchyShell.menuButton, OmarchyShell.keystrokeWindows, OmarchyShell.pomodoro)
}

/** A typed argument for OmarchyShell.barWidgets: `widget("x").left.before("y")` reads as the bar does. */
private class Widget(private val id: String) {
    private var section = ""
    val left get() = apply { section = "left" }
    val right get() = apply { section = "right" }
    fun before(neighbour: String) = "$id $section before $neighbour"
    fun after(neighbour: String) = "$id $section after $neighbour"
}

private fun widget(id: String) = Widget(id)
