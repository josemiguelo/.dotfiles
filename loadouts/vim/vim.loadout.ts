import { program, withBrew } from "loadout";

export const vim = program("vim", { canBeInstalled: [withBrew] });
