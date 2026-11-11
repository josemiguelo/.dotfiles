# 1Password: the app (its repo in .loadout/ on Fedora) and its CLI. Omarchy's
# setup of it is ../.omarchy's omarchy-1password.

program "1password" {
  description = "1Password desktop app"

  via "dnf-repo" {
    params = { repofile = file(".loadout/1password.repo") }
  }

  # Omarchy's [omarchy] repo; omarchy-1password finishes the setup.
  via "omarchy" {}
}

program "1password-cli" {
  description = "1Password CLI (op)"
  install_via = [omarchy, brew-cask]
}

# `op` signed in through the app: what any step reading a secret from
# 1Password runs after.
script "onepassword-cli" {
  description = "1Password CLI connected to an account through the app"
  managed_by  = ".loadout/cli-integration.ts"
  run_after   = [program["1password"], program["1password-cli"]]
}
