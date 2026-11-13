import { brewCask, program } from "loadout";

// The macOS launcher; its dotfiles are the script commands it runs.
export const raycast = program("raycast", { description: "Raycast launcher", install: [brewCask] });
