# Fedora's full vim is vim-enhanced (vim-minimal is the stub); Homebrew's
# formula is vim.
program "vim" {
  via "dnf" { pkg = "vim-enhanced" }
  install_via = [brew]
}
