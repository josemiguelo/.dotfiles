# curl: downloads in install commands, and Homebrew's Linux install needs it.

program "curl" {
  install_via = [dnf, omarchy]
}
