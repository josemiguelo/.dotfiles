import { program, withBrew } from "loadout";

export const qemu = program("qemu", { canWait: "VMs: a large Homebrew install nothing in setup needs", canBeInstalled: [withBrew] });
