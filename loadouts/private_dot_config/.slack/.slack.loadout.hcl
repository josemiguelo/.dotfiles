# Slack: Slack's repo on Fedora (.loadout/slack.repo), the AUR elsewhere.

program "slack" {
  description = "Slack desktop app"
  later       = "a large app download; nothing in setup needs it"

  via "dnf-repo" {
    params = { repofile = file(".loadout/slack.repo") }
  }

  via "omarchy-aur" { pkg = "slack-desktop" }  # Slack's own build, repackaged
}
