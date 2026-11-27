import { program, withBrew } from "loadout";

export const trashCli = program("trash-cli", { canBeInstalled: [withBrew] });
