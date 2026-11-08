# Hyprland on Omarchy: settings, bindings, window sizes and app hotkeys,
# each written into ~/.config/hypr/ as a managed block. The scripts source
# Omarchy's helpers in ../.omarchy/.loadout/lib/.

# Hyprland on Omarchy: settings, bindings, window sizes and app hotkeys:
# `run = [script.omarchy-harpoon]`.

# hypr-config/<file>.lua into ~/.config/hypr/<file>.lua, for the files the
# machine names.
script "omarchy-hypr-config" {
  description = "Hyprland settings from hypr-config/*.lua"
  managed_by  = ".loadout/omarchy-hypr-config.ts"
}

script "omarchy-close-window-key" {
  description = "SUPER+Q closes windows"
  managed_by  = ".loadout/omarchy-close-window-key.ts"
}

# The email/calendar keys rebound from HEY to Gmail and Google Calendar web
# apps.
script "omarchy-google-bindings" {
  description = "email and calendar keys open Gmail and Google Calendar"
  managed_by  = ".loadout/omarchy-google-bindings.ts"
}

# btop's window at the machine's size (pixels or a share: 80% 80%), not
# 875x600.
script "omarchy-activity-monitor-size" {
  description = "activity monitor (btop) window size"
  managed_by  = ".loadout/omarchy-activity-monitor-size.ts"
}

# Hotkeys on Hyper, like Raycast's: jump to an app, or show a scratchpad
# workspace of its own (AI, Media, Social, Notes) on the window last used there;
# Omarchy's scratchpad on Hyper+Escape. The engine is
# github.com/josemiguelo/omarchy-harpoon, which omarchy-plugins installs.
script "omarchy-harpoon" {
  description = "Hyper+letter app and overlay hotkeys, the scratchpad on Hyper+Escape"
  managed_by  = ".loadout/omarchy-harpoon.ts"
  run_after   = [script.omarchy-plugins]
}

# The machine's dark and light themes, for omarchy-theme-mode-toggle
# (Hyper+Enter).
script "omarchy-theme-mode" {
  description = "Hyper+Enter switches between the dark and light theme"
  managed_by  = ".loadout/omarchy-theme-mode.ts"
}
