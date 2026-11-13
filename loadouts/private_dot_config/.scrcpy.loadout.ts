import { brew, program } from "loadout";

export const scrcpy = program("scrcpy", {
  description: "scrcpy Android screen mirroring",
  later: "a large Homebrew install; nothing in setup needs it",
  install: [brew],
});
