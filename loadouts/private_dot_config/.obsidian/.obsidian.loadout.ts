// Obsidian: the notes app.
import { omarchy, program } from "loadout";

// Omarchy preinstalls Arch's package and its launch flags.
export const obsidian = program("obsidian", { description: "Obsidian notes", install: [omarchy] });
