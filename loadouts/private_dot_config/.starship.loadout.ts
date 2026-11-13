// starship: the prompt. Its config is starship.toml, beside this file.
import { brew, omarchy, program } from "loadout";

// The shell prompt; its config is loadouts/private_dot_config/starship.toml,
// one file among others'.
export const starship = program("starship", { install: [brew, omarchy] });
