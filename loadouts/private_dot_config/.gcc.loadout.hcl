# gcc: the C compiler builds need (Homebrew's Linux install).

program "gcc" {
  install_via = [dnf, omarchy]
}
