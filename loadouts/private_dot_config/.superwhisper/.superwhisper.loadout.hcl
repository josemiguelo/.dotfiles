# Superwhisper on macOS: the cask. On Omarchy it's Omarchy's own
# (omarchy-default-dictation).
program "superwhisper" {
  description = "Superwhisper dictation"
  install_via = [brew-cask]
}

# Linux: Superwhisper's settings, one key=value per argument, through its own
# CLI: "processing=offline" (cloud | offline | offline_lite; an offline mode's
# models are downloaded first) and any general setting with a string value
# ("language=auto", "tone=casual"). The machine names them:
# `args(script.superwhisper-settings, "processing=offline", "language=auto")`.
# There's no setting for a list of languages; offline, `auto` detects the
# spoken one (English and Spanish both come out right).
script "superwhisper-settings" {
  description = "Superwhisper's processing mode and settings"
  managed_by  = ".loadout/superwhisper-settings.sh"
  run_after   = [script.omarchy-default-dictation]
}
