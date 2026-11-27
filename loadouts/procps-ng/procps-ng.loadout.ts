// procps-ng: ps, free and friends; Homebrew's Linux install needs it.
import { program, withOmarchy } from "loadout";

export const procpsNg = program("procps-ng", { canBeInstalled: [withOmarchy] });
