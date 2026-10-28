// Voxtype: push-to-talk dictation, and its first-time setup on macOS. Omarchy's
// setup of it is .dictation.loadout.kt.
package loadouts

import loadout.dsl.*

// Push-to-talk speech-to-text. macOS: a cask from its own tap. Omarchy:
// voxtype-bin from [omarchy], which .dictation.loadout.kt sets up around it.
val voxtype = program(
    name = "voxtype",
    description = "Voxtype push-to-talk speech-to-text",
) {
    installVia(
        tapCask(tap = "peteonrails/voxtype"),
        omarchy(pkg = "voxtype-bin"),
    )
}

// macOS: the first-time setup, as a step that stays pending until
// Voxtype.app exists.
// It runs `voxtype configure` (interactive) and the app bundle, then prints
// the permissions left for System Settings.
val voxtypeSetup = script(
    name = "voxtype-setup",
    description = "Voxtype configured, Voxtype.app created (macOS)",
) {
    managedBy(".loadout/voxtype-setup.sh")
    needsSudo()
    runAfter(voxtype)
}
