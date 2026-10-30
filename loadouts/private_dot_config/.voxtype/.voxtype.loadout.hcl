# Voxtype: push-to-talk dictation, and its first-time setup on macOS. Omarchy's
# setup of it is .dictation.loadout.hcl.

# Push-to-talk speech-to-text. macOS: a cask from its own tap. Omarchy:
# voxtype-bin from [omarchy], which .dictation.loadout.hcl sets up around it.
program "voxtype" {
  description = "Voxtype push-to-talk speech-to-text"

  via "brew-tap-cask" {
    params = { tap = "peteonrails/voxtype" }
  }

  via "omarchy" { pkg = "voxtype-bin" }
}

# macOS: the first-time setup, as a step that stays pending until
# Voxtype.app exists.
# It runs `voxtype configure` (interactive) and the app bundle, then prints
# the permissions left for System Settings.
script "voxtype-setup" {
  description = "Voxtype configured, Voxtype.app created (macOS)"
  managed_by  = ".loadout/voxtype-setup.sh"
  needs_sudo  = true
  run_after   = [program.voxtype]
}
