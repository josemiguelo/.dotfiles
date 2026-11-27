import { program, withBrew, withOmarchy } from "loadout";

export const lazygit = program("lazygit", { canBeInstalled: [withBrew, withOmarchy] });
