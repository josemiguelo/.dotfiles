// fzf: the fuzzy finder. Its zsh side lives in zsh's conf.d/ and plugins/.
import { brew, omarchy, program } from "loadout";

export const fzf = program("fzf", { install: [brew, omarchy] });
