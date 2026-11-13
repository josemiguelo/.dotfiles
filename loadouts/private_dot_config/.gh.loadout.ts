import { brew, program } from "loadout";

export const gh = program("gh", { description: "GitHub CLI", install: [brew] });
