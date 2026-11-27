import { program, withBrew, withOmarchy } from "loadout";

export const gitDelta = program("git-delta", { canBeInstalled: [withBrew, withOmarchy] });
