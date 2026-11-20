// Obsidian: the notes app.
import { omarchy, program, script } from "loadout";

// Omarchy preinstalls Arch's package and its launch flags.
export const obsidian = program("obsidian", { description: "Obsidian notes", install: [omarchy] });

// The vault, synced by Obsidian Sync: on a new machine it waits, like
// onepassword-cli, for the login and the sync it can't do itself:
// args(obsidianVault, "<vault>").
export const obsidianVault = script("obsidian-vault", {
  description: "the Obsidian vault, brought by Obsidian Sync",
  managedBy: ".loadout/vault.ts",
  runAfter: [obsidian],
});

// The Copilot plugin in that vault, talking to the local llama-server and Miyo
// (docs/local-llm.md):
// args(obsidianCopilot, "<vault>", "<base url>/v1", "<model alias>", "<miyo max results>").
export const obsidianCopilot = script("obsidian-copilot", {
  description: "Copilot plugin in the vault, on the local LLM",
  managedBy: ".loadout/copilot.ts",
  runAfter: [obsidian, obsidianVault],
});
