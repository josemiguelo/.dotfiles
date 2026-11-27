// stremio: the media center, from Flathub.
import { program, withFlatpak } from "loadout";

export const stremio = program("stremio", {
  description: "Stremio media center",
  canWait: "a big Flathub download; nothing else needs it",
  canBeInstalled: [withFlatpak({ packageName: "com.stremio.Stremio" })],
});
