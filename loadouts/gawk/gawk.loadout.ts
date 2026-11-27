// gawk: GNU's, for scripts written for it (macOS ships BSD tools).
import { program, withBrew } from "loadout";

export const gawk = program("gawk", { canBeInstalled: [withBrew] });
