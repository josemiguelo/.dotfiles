# Firefox: Mozilla's rpm on Fedora (.loadout/install-firefox.sh), and the
# flatpak gone.

program "firefox" {
  description = "Firefox browser"

  via "dnf" {
    installed_by = ".loadout/install-firefox.sh"
    needs_sudo   = true
  }
}

# The rpm firefox wins; the flatpak goes.
script "remove-firefox-flatpak" {
  description = "remove the firefox flatpak"
  run         = "flatpak --user uninstall --delete-data -y org.mozilla.firefox"
  check       = "! flatpak --user info org.mozilla.firefox >/dev/null 2>&1"
}
