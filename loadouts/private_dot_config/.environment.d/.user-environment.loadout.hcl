# Linux (systemd user manager): the user environment matches
# ~/.config/environment.d.
script "user-environment" {
  description = "systemd user environment matches ~/.config/environment.d"
  managed_by  = ".loadout/user-environment.sh"
}
