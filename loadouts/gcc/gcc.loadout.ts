// gcc: the C compiler builds need (Homebrew's Linux install).
import { program, withOmarchy } from "loadout";

export const gcc = program("gcc", { canBeInstalled: [withOmarchy] });
