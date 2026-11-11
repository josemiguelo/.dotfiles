# stremio: the media center, from Flathub.

program "stremio" {
  description = "Stremio media center"
  later       = "a big Flathub download; nothing else needs it"
  via "flatpak" { pkg = "com.stremio.Stremio" }
}
