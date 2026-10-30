# 1Password: the app (its repo in .loadout/ on Fedora) and its CLI. Omarchy's
# setup of it is ../.omarchy's omarchy-1password.

program "1password" {
  description = "1Password desktop app"

  via "dnf-repo" {
    params = { repofile = file(".loadout/1password.repo") }
  }

  # Omarchy's [omarchy] repo; omarchy-1password finishes the setup.
  install_via = [omarchy]
}

program "1password-cli" {
  description = "1Password CLI (op)"
  install_via = [omarchy, brew-cask]
}
