# Identity and delta as pager, written into ~/.gitconfig (not a chezmoi file).
script "setup-git" {
  description = "git identity and delta configuration"
  managed_by  = ".loadout/setup-git.sh"
}

program "git" {
  install_via = [dnf, omarchy, pacman]
}
