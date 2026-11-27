import { program, withBrew, withOmarchy } from "loadout";

export const ripgrep = program("ripgrep", { canBeInstalled: [withBrew, withOmarchy] });
