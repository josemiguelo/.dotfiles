import { program, withBrewCask } from "loadout";

export const lunar = program("lunar", { description: "Lunar -- external display brightness/contrast control", canBeInstalled: [withBrewCask] });
