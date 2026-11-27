import { program, withBrewCask } from "loadout";

export const obs = program("obs", {
  description: "OBS Studio -- screen recording/streaming",
  canWait: "a big app download; nothing in setup needs it",
  canBeInstalled: [withBrewCask],
});
