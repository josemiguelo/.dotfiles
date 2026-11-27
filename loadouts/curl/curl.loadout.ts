// curl: downloads in install commands, and Homebrew's Linux install needs it.
import { program, withOmarchy } from "loadout";

export const curl = program("curl", { canBeInstalled: [withOmarchy] });
