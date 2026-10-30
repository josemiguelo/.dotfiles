# Keychron HID nodes open to the logged-in user (udev uaccess), so the
# Launcher (WebHID) connects.
script "keychron-launcher-access" {
  description = "Keychron Launcher can reach the keyboard (WebHID)"
  managed_by  = ".loadout/launcher-access.sh"
  needs_sudo  = true
}
