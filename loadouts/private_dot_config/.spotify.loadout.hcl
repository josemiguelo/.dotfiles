# spotify: the music app. Its Omarchy launch flags are spotify-flags.conf,
# beside this file.

program "spotify" {
  description = "Spotify music streaming"
  install_via = [omarchy]  # Omarchy's own repo carries it
  via "brew-cask" { spare = "for macOS; no Mac installs it yet" }
}
