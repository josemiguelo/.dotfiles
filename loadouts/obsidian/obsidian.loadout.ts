// Obsidian: the notes app.
import { program, script, withOmarchy } from "loadout";

// Omarchy preinstalls Arch's package and its launch flags.
export const obsidian = program("obsidian", { description: "Obsidian notes", canBeInstalled: [withOmarchy] });

// The vault, synced by Obsidian Sync: on a new machine it waits, like
// onepassword-signin, for the login and the sync it can't do itself.
export const obsidianVault = script("obsidian-vault", {
  description: "the Obsidian vault, brought by Obsidian Sync",
  module: () => import("./.loadout/vault.ts"),
  rules: () => import("./.loadout/vault.rules.ts"),
  runAfter: [obsidian],
});

// The Copilot plugin in that vault, talking to the local llama-server and Miyo
// (docs/local-llm.md).
export const obsidianCopilot = script("obsidian-copilot", {
  description: "Copilot plugin in the vault, on the local LLM",
  module: () => import("./.loadout/copilot.ts"),
  rules: () => import("./.loadout/copilot.rules.ts"),
  runAfter: [obsidian, obsidianVault],
});

// Agent Chat's OpenCode in that vault: when it compacts, and the only skills it
// sees.
export const obsidianOpencode = script("obsidian-opencode", {
  description: "Agent Chat's OpenCode sized for the local LLM",
  module: () => import("./.loadout/opencode.ts"),
  rules: () => import("./.loadout/opencode.rules.ts"),
  runAfter: [obsidianVault],
});

// What Agent Chat's grep skips in that vault, unless it names the folder.
export const obsidianRgignore = script("obsidian-rgignore", {
  description: "Agent Chat's grep kept to the notes",
  module: () => import("./.loadout/rgignore.ts"),
  rules: () => import("./.loadout/rgignore.rules.ts"),
  runAfter: [obsidianVault],
});
