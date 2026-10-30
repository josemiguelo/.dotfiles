# chezmoi: the dotfiles manager and its checkout (this repo). loadout
# applies the dotfiles itself; these scripts watch the checkout's git side.

program "chezmoi" {
  install_via = [brew, omarchy, pacman]
}

locals {
  dotfiles_checkout = "$HOME/.local/share/chezmoi"
  dotfiles_https    = "https://github.com/josemiguelo/.dotfiles.git"
  dotfiles_ssh      = "git@github.com:josemiguelo/.dotfiles.git"
}

# The dotfiles checkout's git side: `run = [script.dotfiles-pull]`.

# Pulls over https, pushes over ssh: the repo is public, so pulling works
# before GitHub knows this machine's key (github-ssh-key).
script "dotfiles-ssh-remote" {
  description = "point the chezmoi checkout's pushes at the ssh dotfiles remote"
  run = [
    "git -C ${local.dotfiles_checkout} remote set-url origin ${local.dotfiles_https}",
    "git -C ${local.dotfiles_checkout} config remote.origin.pushurl ${local.dotfiles_ssh}",
  ]
  check = [
    "test \"$(git -C ${local.dotfiles_checkout} config --get remote.origin.url)\" = ${local.dotfiles_https}",
    "test \"$(git -C ${local.dotfiles_checkout} config --get remote.origin.pushurl)\" = ${local.dotfiles_ssh}",
  ]
}

# Is the local source behind origin? (throttled fetch, fail-soft offline).
# Converge = pull only.
script "dotfiles-pull" {
  description   = "pull dotfiles source when behind its origin"
  managed_by    = ".loadout/pull.sh"
  maintain_only = true
}

# Local edits origin hasn't seen. After the pull, so one run rebases before it
# pushes.
script "dotfiles-push" {
  description   = "push dotfiles source when ahead of its origin"
  managed_by    = ".loadout/push.sh"
  run_after     = [script.dotfiles-pull]
  maintain_only = true
}

# What every machine runs for its dotfiles checkout: `run = [local.dotfiles_all]`.
locals {
  dotfiles_all = [
    script.dotfiles-pull,
    script.dotfiles-push,
    script.dotfiles-ssh-remote,
  ]
}
