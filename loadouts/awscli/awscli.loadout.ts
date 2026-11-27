import { program, withBrew } from "loadout";

export const awscli = program("awscli", { canWait: "a large Homebrew install; nothing in setup needs it", canBeInstalled: [withBrew] });
