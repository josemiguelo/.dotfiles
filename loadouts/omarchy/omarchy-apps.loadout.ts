// Omarchy's defaults and agents: the default browser and dictation backend,
// and its agent launchers pruned.
import { script } from "loadout";
import { brave, omarchyBrave } from "../brave/brave.loadout.ts";

// Omarchy's own setup of one app lives with that app (omarchy-brave in
// ../brave/, omarchy-1password in ../1password/, …); what's here is Omarchy's.

// The default browser, named by the machine:
// `omarchyDefaultBrowser({ browser: "brave" })`.
export const omarchyDefaultBrowser = script("omarchy-default-browser", {
  description: "Omarchy's default browser",
  module: () => import("./.loadout/omarchy-default-browser-arch.ts"),
  rules: () => import("./.loadout/omarchy-default-browser-arch.rules.ts"),
  runAfter: [brave, omarchyBrave],
});

// Superwhisper as the dictation backend Omarchy's keys (Alt+Space, Right Alt)
// run, set by Omarchy's own installer, unattended (--background): it installs
// superwhisper-bin when missing (Omarchy 4.5 ships it, but a machine upgraded
// from before may not have it), runs its per-user setup and makes it the
// backend. What a fresh 4.5 install's first run does.
export const omarchyDefaultDictation = script("omarchy-default-dictation", {
  description: "Superwhisper as Omarchy's dictation backend",
  runCommand: "omarchy-install-dictation-superwhisper --background",
  checkCommand: 'test "$(omarchy default dictation 2>/dev/null)" = superwhisper',
  needsSudo: true,
});

// Omarchy's agent launchers (~/.local/bin) and seeded configs (~/.config),
// pruned to the agents the machine names.
export const omarchyAgentsPrune = script("omarchy-agents-prune", {
  description: "only the Omarchy agent launchers and configs in use",
  module: () => import("./.loadout/omarchy-agents-prune.ts"),
  rules: () => import("./.loadout/omarchy-agents-prune.rules.ts"),
});
