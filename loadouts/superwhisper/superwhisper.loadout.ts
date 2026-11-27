import { program, script, withBrewCask } from "loadout";
import { omarchyDefaultDictation } from "../omarchy/omarchy-apps.loadout.ts";

// Superwhisper on macOS: the cask. On Omarchy it's Omarchy's own
// (omarchy-default-dictation).
export const superwhisper = program("superwhisper", { description: "Superwhisper dictation", canBeInstalled: [withBrewCask] });

// Linux: Superwhisper's settings, through its own CLI: the processing mode (an
// offline one's models are downloaded first) and any general setting with a
// string value (language, tone).
// There's no setting for a list of languages; offline, `auto` detects the
// spoken one (English and Spanish both come out right).
export const superwhisperSettings = script("superwhisper-settings", {
  description: "Superwhisper's processing mode and settings",
  canWait: "an offline mode downloads gigabytes of models; dictation can wait for them",
  module: () => import("./.loadout/superwhisper-settings.ts"),
  rules: () => import("./.loadout/superwhisper-settings.rules.ts"),
  runAfter: [omarchyDefaultDictation],
});

// Linux: its offline workers on one GPU, by PCI id (`lspci -nn`), where a
// discrete GPU is someone else's (the T2's Radeon is llama-server's).
export const superwhisperGpu = script("superwhisper-gpu", {
  description: "Superwhisper's offline workers on one GPU",
  module: () => import("./.loadout/gpu.ts"),
  rules: () => import("./.loadout/gpu.rules.ts"),
  runAfter: [omarchyDefaultDictation],
});
