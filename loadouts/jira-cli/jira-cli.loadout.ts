import { program, withBrew } from "loadout";

export const jiraCli = program("jira-cli", { description: "Jira CLI", canBeInstalled: [withBrew] });
