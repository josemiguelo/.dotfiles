# kitty: the terminal, the font its kitty.conf names, and (on Omarchy) kitty
# as the terminal everything opens.

# Fedora: the solopasha COPR (fresher than the distro's); dnf-plugins-core
# now comes from the dnf-copr installer's `requires`. macOS: the cask, the
# same signed .dmg from kitty's GitHub releases.
program "kitty" {
  description = "kitty terminal emulator"

  via "dnf-copr" {
    params = { copr = "solopasha/kitty" }
  }

  install_via = [omarchy, brew-cask]
}

# The family kitty.conf names (FiraCode Nerd Font Mono) on Linux.
program "ttf-firacode-nerd" {
  description = "FiraCode Nerd Font"
  install_via = [omarchy]
}

script "omarchy-default-terminal" {
  description = "kitty as omarchy's default terminal"
  managed_by  = ".loadout/default-terminal.sh"
  run_after   = [program.kitty]
}
