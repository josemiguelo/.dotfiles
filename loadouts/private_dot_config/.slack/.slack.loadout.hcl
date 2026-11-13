# Slack: from the AUR.

program "slack" {
  description = "Slack desktop app"
  later       = "a large app download; nothing in setup needs it"

  via "omarchy-aur" { pkg = "slack-desktop" }  # Slack's own build, repackaged
}
