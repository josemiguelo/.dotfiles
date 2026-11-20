import { brewCask, program, script } from "loadout";
import { omarchyDefaultDictation } from "../.omarchy/.omarchy-apps.loadout.ts";

// Superwhisper on macOS: the cask. On Omarchy it's Omarchy's own
// (omarchy-default-dictation).
export const superwhisper = program("superwhisper", { description: "Superwhisper dictation", install: [brewCask] });

// Linux: Superwhisper's settings, one key=value per argument, through its own
// CLI: "processing=offline" (cloud | offline | offline_lite; an offline mode's
// models are downloaded first) and any general setting with a string value
// ("language=auto", "tone=casual"). The machine names them:
// `args(superwhisperSettings, "processing=offline", "language=auto")`.
// There's no setting for a list of languages; offline, `auto` detects the
// spoken one (English and Spanish both come out right).
export const superwhisperSettings = script("superwhisper-settings", {
  description: "Superwhisper's processing mode and settings",
  later: "an offline mode downloads gigabytes of models; dictation can wait for them",
  managedBy: ".loadout/superwhisper-settings.ts",
  runAfter: [omarchyDefaultDictation],
});

// Linux: its offline workers on one GPU, by PCI id (`lspci -nn`), where a
// discrete GPU is someone else's (the T2's Radeon is llama-server's):
// `args(superwhisperGpu, "8086:3e9b")`.
export const superwhisperGpu = script("superwhisper-gpu", {
  description: "Superwhisper's offline workers on one GPU",
  managedBy: ".loadout/gpu.ts",
  runAfter: [omarchyDefaultDictation],
});
