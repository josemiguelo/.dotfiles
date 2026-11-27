// spotify: the music app. Its Omarchy launch flags are
// home/private_dot_config/spotify-flags.conf.
import { program, withBrewCask, withOmarchy } from "loadout";

export const spotify = program("spotify", {
  description: "Spotify music streaming",
  canBeInstalled: [
    // Omarchy's own repo carries it.
    withOmarchy,
    withBrewCask({ keepUnused: "for macOS; no Mac installs it yet" }),
  ],
});
