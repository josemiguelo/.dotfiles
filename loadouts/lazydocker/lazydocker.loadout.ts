import { program, withBrew, withOmarchy } from "loadout";

export const lazydocker = program("lazydocker", { canBeInstalled: [withBrew, withOmarchy] });
