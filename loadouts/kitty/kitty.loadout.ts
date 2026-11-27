// kitty: the terminal, the font its kitty.conf names, and (on Omarchy) kitty
// as the terminal everything opens.
import { program, script, withBrewCask, withOmarchy } from "loadout";

// macOS: the cask, the same signed .dmg from kitty's GitHub releases.
export const kitty = program("kitty", { description: "kitty terminal emulator", canBeInstalled: [withOmarchy, withBrewCask] });

// The family kitty.conf names (FiraCode Nerd Font Mono) on Linux.
export const ttfFiracodeNerd = program("ttf-firacode-nerd", { description: "FiraCode Nerd Font", canBeInstalled: [withOmarchy] });

export const omarchyDefaultTerminal = script("omarchy-default-terminal", {
  description: "kitty as omarchy's default terminal",
  module: () => import("./.loadout/default-terminal.ts"),
  runAfter: [kitty],
});
