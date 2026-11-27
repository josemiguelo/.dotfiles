import { program, withBrew, withOmarchy } from "loadout";

export const yazi = program("yazi", { canBeInstalled: [withBrew, withOmarchy] });
