# Local replacements of Omarchy commands, first on the PATH of everything
# Hyprland starts. The scripts source .loadout/lib/.

# Local replacements of Omarchy commands: `run = [script.omarchy-command-overrides]`.
script "omarchy-command-overrides" {
  description = "local replacements of Omarchy commands come first"
  managed_by  = ".loadout/omarchy-command-overrides.sh"
}

# `omarchy-brightness-keyboard off` saves 0 over the real level; the wrapper
# skips `off` on a dark light. Goes once Omarchy is fixed.
script "omarchy-keyboard-backlight-guard" {
  description = "keyboard backlight comes back after sleep"
  managed_by  = ".loadout/omarchy-keyboard-backlight-guard.sh"
  run_after   = [script.omarchy-command-overrides]
}
