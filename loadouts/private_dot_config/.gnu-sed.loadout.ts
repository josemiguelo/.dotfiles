// gnu-sed: GNU's, for scripts written for it (macOS ships BSD tools).
import { brew, program } from "loadout";

export const gnuSed = program("gnu-sed", { install: [brew] });
