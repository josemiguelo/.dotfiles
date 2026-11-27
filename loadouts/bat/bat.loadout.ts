import { program, withBrew, withOmarchy } from "loadout";

export const bat = program("bat", { canBeInstalled: [withBrew, withOmarchy] });
