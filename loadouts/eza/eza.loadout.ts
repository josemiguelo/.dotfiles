import { program, withBrew, withOmarchy } from "loadout";

export const eza = program("eza", { canBeInstalled: [withBrew, withOmarchy] });
