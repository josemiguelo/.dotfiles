# kitty: the terminal, the font its kitty.conf names, and (on Omarchy) kitty
# as the terminal everything opens.

# macOS: the cask, the same signed .dmg from kitty's GitHub releases.
program "kitty" {
  description = "kitty terminal emulator"
  install_via = [omarchy, brew-cask]
}

# The family kitty.conf names (FiraCode Nerd Font Mono) on Linux.
program "ttf-firacode-nerd" {
  description = "FiraCode Nerd Font"
  install_via = [omarchy]
}

script "omarchy-default-terminal" {
  description = "kitty as omarchy's default terminal"
  managed_by  = ".loadout/default-terminal.ts"
  run_after   = [program.kitty]
}
