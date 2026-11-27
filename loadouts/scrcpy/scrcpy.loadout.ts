import { program, withBrew } from "loadout";

export const scrcpy = program("scrcpy", {
  description: "scrcpy Android screen mirroring",
  canWait: "a large Homebrew install; nothing in setup needs it",
  canBeInstalled: [withBrew],
});
