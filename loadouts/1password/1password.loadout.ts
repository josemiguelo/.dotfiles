// 1Password: the app and its CLI, and Omarchy's setup of it (omarchy-1password).
import { program, script, withBrewCask, withOmarchy } from "loadout";

// Omarchy's [omarchy] repo; omarchy-1password finishes the setup.
export const onePassword = program("1password", { description: "1Password desktop app", canBeInstalled: [withOmarchy] });

export const n1passwordCli = program("1password-cli", { description: "1Password CLI (op)", canBeInstalled: [withOmarchy, withBrewCask] });

// `op` signed in through the app: what any step reading a secret from
// 1Password runs after (1password-cli above is the program that installs op).
export const onepasswordSignin = script("onepassword-signin", {
  description: "1Password CLI connected to an account through the app",
  module: () => import("./.loadout/cli-integration.ts"),
  runAfter: [onePassword, n1passwordCli],
});

// Omarchy's installer (Chromium extension entry), started unscaled at login,
// Ctrl+Shift+Space for Quick Access.
export const omarchy1password = script("omarchy-1password", {
  description: "1Password via Omarchy's installer, unscaled, Ctrl+Shift+Space Quick Access",
  module: () => import("./.loadout/omarchy-1password.ts"),
  needsSudo: true,
  runAfter: [onePassword, n1passwordCli],
});
