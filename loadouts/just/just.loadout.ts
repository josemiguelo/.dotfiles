import { program, withBrew } from "loadout";

export const just = program("just", { canBeInstalled: [withBrew] });
