// 1Password: the app and its CLI. Omarchy's setup of it is ../.omarchy's
// omarchy-1password.
import { brewCask, omarchy, program, script } from "loadout";

// Omarchy's [omarchy] repo; omarchy-1password finishes the setup.
export const onePassword = program("1password", { description: "1Password desktop app", install: [omarchy] });

export const n1passwordCli = program("1password-cli", { description: "1Password CLI (op)", install: [omarchy, brewCask] });

// `op` signed in through the app: what any step reading a secret from
// 1Password runs after.
export const onepasswordCli = script("onepassword-cli", {
  description: "1Password CLI connected to an account through the app",
  managedBy: ".loadout/cli-integration.ts",
  runAfter: [onePassword, n1passwordCli],
});
