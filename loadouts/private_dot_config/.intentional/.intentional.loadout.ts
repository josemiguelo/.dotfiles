// Intentional's desktop guard (github.com/josemiguelo/intentional): group
// budgets for apps and sites on Hyprland, measured and enforced by a daemon
// (a systemd user service) and its Brave extension. Its groups live in
// ~/.config/intentional/groups.json, kept out of this repo.
import { custom, program, script } from "loadout";
import { onepasswordCli } from "../.1password/.1password.loadout.ts";
import { brave } from "../.brave.loadout.ts";
import { libxcryptCompat } from "../.libxcrypt-compat.loadout.ts";

// The latest GitHub release, installed by the install.sh it carries; no
// checkout, JDK or Kotlin/Native needed. The daemon links libcrypt.so.1.
export const intentional = program("intentional", {
  description: "Intentional's desktop guard: app and site budgets (Hyprland + Brave)",
  dependsOn: [libxcryptCompat, brave],
  install: [
    custom({
        managedBy: ".loadout/intentional.ts",
        // Its check prints "intentional <version>" once everything is in place.
        regex: "intentional ([0-9][0-9.]*)",
      }),
  ],
  path: ["$HOME/.local/bin"],
  version: "intentional --version",
  updatesManagedBy: ".loadout/outdated-intentional.ts",
});

// Sync's secrets from 1Password, so a new machine syncs once installed. The
// device name comes from the machine: `args(intentionalSync, "<name>")`.
export const intentionalSync = script("intentional-sync", {
  description: "Intentional's sync config, from 1Password",
  managedBy: ".loadout/sync-config.ts",
  runAfter: [onepasswordCli, intentional],
});
