// coreutils: GNU's, for scripts written for it (macOS ships BSD tools).
import { brew, program } from "loadout";

export const coreutils = program("coreutils", { install: [brew] });
