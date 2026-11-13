import { brew, omarchy, program } from "loadout";

export const treeSitterCli = program("tree-sitter-cli", { install: [brew, omarchy] });
