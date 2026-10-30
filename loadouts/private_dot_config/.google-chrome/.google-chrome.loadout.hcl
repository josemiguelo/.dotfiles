# Google Chrome: Google's rpm on Fedora (.loadout/install-chrome.sh).

program "google-chrome-stable" {
  description = "Google Chrome browser"

  via "dnf" {
    installed_by = ".loadout/install-chrome.sh"
    needs_sudo   = true
  }
}
