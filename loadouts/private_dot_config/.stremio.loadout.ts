// stremio: the media center, from Flathub.
import { flatpak, program, via } from "loadout";

export const stremio = program("stremio", {
  description: "Stremio media center",
  later: "a big Flathub download; nothing else needs it",
  install: [via(flatpak, { pkg: "com.stremio.Stremio" })],
});
