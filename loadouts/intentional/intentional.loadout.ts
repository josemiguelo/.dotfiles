// Intentional's desktop guard (github.com/josemiguelo/intentional): group
// budgets for apps and sites on Hyprland, measured and enforced by a daemon
// (a systemd user service) and its Brave extension. Its groups live in
// ~/.config/intentional/groups.json, kept out of this repo.
import { program, script, withCustomSteps } from "loadout";
import { onepasswordSignin } from "../1password/1password.loadout.ts";
import { brave } from "../brave/brave.loadout.ts";
import { libxcryptCompat } from "../libxcrypt-compat/libxcrypt-compat.loadout.ts";

// The latest GitHub release, installed by the install.sh it carries; no
// checkout, JDK or Kotlin/Native needed. The daemon links libcrypt.so.1.
export const intentional = program("intentional", {
  description: "Intentional's desktop guard: app and site budgets (Hyprland + Brave)",
  dependsOn: [libxcryptCompat, brave],
  canBeInstalled: [
    withCustomSteps({
        module: () => import("./.loadout/intentional.ts"),
        // Its check prints "intentional <version>" once everything is in place.
        versionRegex: /intentional ([0-9][0-9.]*)/,
      }),
  ],
  searchPath: ["$HOME/.local/bin"],
  versionCommand: "intentional --version",
  updates: () => import("./.loadout/outdated-intentional.ts"),
});

// Sync's secrets from 1Password, so a new machine syncs once installed. The
// device name comes from the machine.
export const intentionalSync = script("intentional-sync", {
  description: "Intentional's sync config, from 1Password",
  module: () => import("./.loadout/sync-config.ts"),
  rules: () => import("./.loadout/sync-config.rules.ts"),
  runAfter: [onepasswordSignin, intentional],
});
