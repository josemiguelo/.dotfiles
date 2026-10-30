# Omarchy web apps: `args(script.omarchy-webapps-remove, "Basecamp", "HEY")`.

# The web apps the machine names, removed the native way and kept removed
# across re-provisioning.
script "omarchy-webapps-remove" {
  description = "Omarchy web apps removed"
  managed_by  = ".loadout/omarchy-webapps-remove.sh"
}

script "omarchy-webapp-gmail" {
  description = "Gmail web app, the default for email links"
  managed_by  = ".loadout/omarchy-webapp-gmail.sh"
  run_after   = [script.omarchy-webapps-remove]  # HEY's launcher claims mailto too
}

script "omarchy-webapp-google-calendar" {
  description = "Google Calendar web app"
  managed_by  = ".loadout/omarchy-webapp-google-calendar.sh"
}

script "omarchy-webapp-claude" {
  description = "Claude web app, on Hyper+C"
  managed_by  = ".loadout/omarchy-webapp-claude.sh"
}
