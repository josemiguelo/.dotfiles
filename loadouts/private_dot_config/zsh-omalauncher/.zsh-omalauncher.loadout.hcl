# zsh for omalauncher's Arch: its plugins as Arch packages, sourced by
# .zshrc; zsh itself and default-shell are ../zsh's.

program "zsh-autosuggestions" {
  install_via = [pacman]
}

program "zsh-syntax-highlighting" {
  install_via = [pacman]
}
