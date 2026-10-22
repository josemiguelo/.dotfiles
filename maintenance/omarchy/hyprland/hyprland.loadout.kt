// Hyprland on Omarchy: settings, bindings, window sizes and app hotkeys,
// each written into ~/.config/hypr/ as a managed block. The scripts source
// ../lib/.
package loadouts

import loadout.dsl.*

/** Hyprland on Omarchy: settings, bindings, window sizes and app hotkeys: `run(Hyprland.harpoon)`. */
object Hyprland {
    /** hypr-config/<file>.lua into ~/.config/hypr/<file>.lua, for the files the machine names. */
    val config = script(
        name = "omarchy-hypr-config",
        description = "Hyprland settings from hypr-config/*.lua",
    ) {
        managedBy("omarchy-hypr-config.sh")
    }

    val closeWindowKey = script(
        name = "omarchy-close-window-key",
        description = "SUPER+Q closes windows",
    ) {
        managedBy("omarchy-close-window-key.sh")
    }

    /** The email/calendar keys rebound from HEY to Gmail and Google Calendar web apps. */
    val googleBindings = script(
        name = "omarchy-google-bindings",
        description = "email and calendar keys open Gmail and Google Calendar",
    ) {
        managedBy("omarchy-google-bindings.sh")
    }

    /** btop's window at the machine's size (pixels or a share: 80% 80%), not 875x600. */
    val activityMonitorSize = script(
        name = "omarchy-activity-monitor-size",
        description = "activity monitor (btop) window size",
    ) {
        managedBy("omarchy-activity-monitor-size.sh")
    }

    /** Per-app hotkeys on Hyper, like Raycast's: jump to the app or show it as an overlay. */
    val harpoon = script(
        name = "omarchy-harpoon",
        description = "Hyper+letter app hotkeys (jump, overlay)",
    ) {
        managedBy("omarchy-harpoon.sh")
    }

    /** The machine's dark and light themes, for omarchy-theme-mode-toggle (Hyper+Enter). */
    val themeMode = script(
        name = "omarchy-theme-mode",
        description = "Hyper+Enter switches between the dark and light theme",
    ) {
        managedBy("omarchy-theme-mode.sh")
    }
}
