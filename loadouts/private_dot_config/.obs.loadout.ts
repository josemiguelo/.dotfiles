import { brewCask, program } from "loadout";

export const obs = program("obs", { description: "OBS Studio -- screen recording/streaming", install: [brewCask] });
