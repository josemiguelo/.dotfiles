# Dictation (Omarchy): Voxtype push-to-talk, set up by Omarchy's own
# installer and moved onto the GPU.

# What Omarchy's dictation installer adds beside voxtype-bin: types the text
# into the focused window.
program "wtype" {
  description = "xdotool type for Wayland (voxtype's typing backend)"
  install_via = [omarchy]
}

# The Textual TUI whose Python package does the Voxtype bar plugin's config
# writes.
program "voxtype-tui" {
  description = "Voxtype's settings TUI and the Voxtype plugin's backend"
  install_via = [omarchy-aur]
}

# The Voxtype plugin's Import file chooser.
program "zenity" {
  description = "GTK dialogs from scripts (the Voxtype plugin's file chooser)"
  install_via = [omarchy]
}

# Voxtype dictation on Omarchy: `run = [script.omarchy-dictation]`.

# The steps of Omarchy's installer, without the question before its ~150MB
# model download.
script "omarchy-dictation" {
  description = "Voxtype dictation, set up the way Omarchy's installer does"
  managed_by  = ".loadout/dictation.sh"
  run_after   = [program.voxtype, program.wtype]
}

# Voxtype's Vulkan build, the service restarted onto it.
script "omarchy-dictation-gpu" {
  description = "Voxtype dictation on the GPU (Vulkan)"
  managed_by  = ".loadout/dictation-gpu.sh"
  needs_sudo  = true
  run_after   = [script.omarchy-dictation]
}
