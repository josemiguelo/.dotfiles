// gcc: the C compiler builds need (Homebrew's Linux install).
import { omarchy, program } from "loadout";

export const gcc = program("gcc", { install: [omarchy] });
