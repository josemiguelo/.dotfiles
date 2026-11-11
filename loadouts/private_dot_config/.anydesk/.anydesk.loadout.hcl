# AnyDesk: its rpm on Fedora (.loadout/install-anydesk.sh), the AUR elsewhere.

program "anydesk" {
  description = "AnyDesk remote desktop"
  later       = "a large app download; nothing in setup needs it"

  via "dnf" {
    installed_by = ".loadout/install-anydesk.sh"
    needs_sudo   = true
  }

  # AnyDesk's own build; its unattended-access service is left disabled.
  via "omarchy-aur" { pkg = "anydesk-bin" }
}
