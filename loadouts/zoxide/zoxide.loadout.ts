import { program, withBrew, withOmarchy } from "loadout";

export const zoxide = program("zoxide", { canBeInstalled: [withBrew, withOmarchy] });
