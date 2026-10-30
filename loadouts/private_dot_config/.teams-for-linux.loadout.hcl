program "teams-for-linux" {
  description = "Microsoft Teams client"

  via "dnf-repo" {
    params = { repofile = "https://repo.teamsforlinux.de/rpm/teams-for-linux.repo" }
  }

  via "omarchy-aur" { pkg = "teams-for-linux-bin" }  # the source package rebuilds Electron
}
