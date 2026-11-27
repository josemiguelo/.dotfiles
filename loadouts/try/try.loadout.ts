import { program, withBrew } from "loadout";

export const tryProgram = program("try", { description: "ephemeral workspace manager", canBeInstalled: [withBrew] });
