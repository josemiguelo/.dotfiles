import { program, withBrew } from "loadout";

export const gh = program("gh", { description: "GitHub CLI", canBeInstalled: [withBrew] });
