import { brew, program } from "loadout";

export const azureCli = program("azure-cli", { description: "Azure CLI", install: [brew] });
