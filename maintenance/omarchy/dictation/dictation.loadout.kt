// Dictation (Omarchy): Voxtype push-to-talk, set up by Omarchy's own
// installer and moved onto the GPU.
package repo

import loadout.dsl.*

/** What Omarchy's dictation installer adds beside voxtype-bin: types the text into the focused window. */
val wtype = program(
    name = "wtype",
    description = "xdotool type for Wayland (voxtype's typing backend)",
) {
    installVia(
        omarchy,
    )
}

/** The Textual TUI whose Python package does the Voxtype bar plugin's config writes. */
val voxtypeTui = program(
    name = "voxtype-tui",
    description = "Voxtype's settings TUI and the Voxtype plugin's backend",
) {
    installVia(
        omarchyAur,
    )
}

/** The Voxtype plugin's Import file chooser. */
val zenity = program(
    name = "zenity",
    description = "GTK dialogs from scripts (the Voxtype plugin's file chooser)",
) {
    installVia(
        omarchy,
    )
}

/** Voxtype dictation on Omarchy: `run(Dictation.setup)`. */
object Dictation {
    /** The steps of Omarchy's installer, without the question before its ~150MB model download. */
    val setup = script(
        name = "omarchy-dictation",
        description = "Voxtype dictation, set up the way Omarchy's installer does",
    ) {
        managedBy("dictation.sh")
        runAfter(voxtype, wtype)
    }

    /** Voxtype's Vulkan build, the service restarted onto it. */
    val gpu = script(
        name = "omarchy-dictation-gpu",
        description = "Voxtype dictation on the GPU (Vulkan)",
    ) {
        managedBy("dictation-gpu.sh")
        needsSudo()
        runAfter(setup)
    }
}
