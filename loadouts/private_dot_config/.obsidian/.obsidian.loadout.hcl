# Obsidian: the notes app.

program "obsidian" {
  description = "Obsidian notes"
  via "flatpak" { pkg = "md.obsidian.Obsidian" }
  # Omarchy preinstalls Arch's package and its launch flags.
  via "omarchy" {}
}
