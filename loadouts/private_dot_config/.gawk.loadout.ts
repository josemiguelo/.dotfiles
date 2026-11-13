// gawk: GNU's, for scripts written for it (macOS ships BSD tools).
import { brew, program } from "loadout";

export const gawk = program("gawk", { install: [brew] });
