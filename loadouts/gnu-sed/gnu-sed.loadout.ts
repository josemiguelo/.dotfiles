// gnu-sed: GNU's, for scripts written for it (macOS ships BSD tools).
import { program, withBrew } from "loadout";

export const gnuSed = program("gnu-sed", { canBeInstalled: [withBrew] });
