// spotify: the music app. Its Omarchy launch flags are spotify-flags.conf,
// beside this file.
import { brewCask, omarchy, program, via } from "loadout";

export const spotify = program("spotify", {
  description: "Spotify music streaming",
  install: [
    // Omarchy's own repo carries it.
    omarchy,
    via(brewCask, { spare: "for macOS; no Mac installs it yet" }),
  ],
});
