import { program, withBrew } from "loadout";

export const azureCli = program("azure-cli", {
  description: "Azure CLI",
  canWait: "a large Homebrew install (its own Python); nothing in setup needs it",
  canBeInstalled: [withBrew],
});
