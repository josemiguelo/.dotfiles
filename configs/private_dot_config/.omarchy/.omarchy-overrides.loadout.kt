// Local replacements of Omarchy commands, first on the PATH of everything
// Hyprland starts. The scripts source lib/omarchy/.
package loadouts

import loadout.dsl.*

/** Local replacements of Omarchy commands: `run(Overrides.commands)`. */
object Overrides {
    val commands = script(
        name = "omarchy-command-overrides",
        description = "local replacements of Omarchy commands come first",
    ) {
        managedBy(".loadout/omarchy-command-overrides.sh")
    }

    /** `omarchy-brightness-keyboard off` saves 0 over the real level; the wrapper skips `off` on a dark light. Goes once Omarchy is fixed. */
    val keyboardBacklightGuard = script(
        name = "omarchy-keyboard-backlight-guard",
        description = "keyboard backlight comes back after sleep",
    ) {
        managedBy(".loadout/omarchy-keyboard-backlight-guard.sh")
        needsSudo()
        runAfter(commands)
    }
}
