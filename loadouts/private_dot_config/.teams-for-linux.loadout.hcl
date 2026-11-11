program "teams-for-linux" {
  description = "Microsoft Teams client"
  later       = "a large app download; nothing in setup needs it"

  via "dnf-repo" {
    params = { repofile = "https://repo.teamsforlinux.de/rpm/teams-for-linux.repo" }
  }

  via "omarchy-aur" { pkg = "teams-for-linux-bin" }  # the source package rebuilds Electron
}
