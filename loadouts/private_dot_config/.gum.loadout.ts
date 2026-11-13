import { brew, omarchy, program } from "loadout";

// charmbracelet's gum (the dotfiles' gclone and workmux wrappers use it); an
// Omarchy base package.
export const gum = program("gum", { install: [brew, omarchy] });
