// curl: downloads in install commands, and Homebrew's Linux install needs it.
import { omarchy, program } from "loadout";

export const curl = program("curl", { install: [omarchy] });
