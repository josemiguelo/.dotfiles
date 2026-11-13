import { script } from "loadout";

// The FiraCode Nerd Fonts kitty.conf names, where no package carries them
// (macOS).
export const downloadFonts = script("download-fonts", { description: "FiraCode nerd fonts", managedBy: ".loadout/download-fonts.ts" });
