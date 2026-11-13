// procps-ng: ps, free and friends; Homebrew's Linux install needs it.
import { omarchy, program } from "loadout";

export const procpsNg = program("procps-ng", { install: [omarchy] });
