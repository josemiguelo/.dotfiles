import { brew, program } from "loadout";

export const jiraCli = program("jira-cli", { description: "Jira CLI", install: [brew] });
