# AnyDesk: from the AUR.

program "anydesk" {
  description = "AnyDesk remote desktop"
  later       = "a large app download; nothing in setup needs it"

  # AnyDesk's own build; its unattended-access service is left disabled.
  via "omarchy-aur" { pkg = "anydesk-bin" }
}
