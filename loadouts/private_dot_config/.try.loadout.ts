import { brew, program } from "loadout";

export const tryProgram = program("try", { description: "ephemeral workspace manager", install: [brew] });
