import { program, withBrew } from "loadout";

export const wget = program("wget", { canBeInstalled: [withBrew] });
