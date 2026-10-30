# fzf: the fuzzy finder. Its zsh side lives in zsh's conf.d/ and plugins/.

program "fzf" {
  via "brew" {}

  via "dnf" {
    spare = "for a Fedora machine; the fedora profile doesn't install fzf"
  }

  install_via = [omarchy, pacman]
}
