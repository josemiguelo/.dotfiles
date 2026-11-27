import { program, withBrew, withOmarchy } from "loadout";

export const fd = program("fd", { canBeInstalled: [withBrew, withOmarchy] });
