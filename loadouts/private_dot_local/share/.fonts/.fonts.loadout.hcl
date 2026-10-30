# The FiraCode Nerd Fonts kitty.conf names, where no package carries them
# (macOS, Fedora).
script "download-fonts" {
  description = "FiraCode nerd fonts"
  managed_by  = ".loadout/download-fonts.sh"
}
