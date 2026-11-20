// Miyo (miyo.md): local semantic search for Obsidian Copilot V4. It indexes
// the vault with its own embedding model and vector database, and answers the
// agents' searches by meaning (docs/local-llm.md). Its index lives in
// ~/.config/Miyo, kept out of this repo.
import { custom, omarchy, program, script } from "loadout";

// AppImages mount themselves with FUSE 2 (libfuse.so.2).
export const fuse2 = program("fuse2", { description: "FUSE 2 library, for AppImages", install: [omarchy] });

// The latest AppImage, checked against the SHA-512 its release publishes; it
// updates itself after that, so loadout reads no version of it.
export const miyo = program("miyo", {
  description: "Miyo: local semantic search for Obsidian Copilot",
  later: "a ~300 MB app download; nothing else needs it",
  dependsOn: [fuse2],
  install: [custom({ managedBy: ".loadout/miyo.ts" })],
  path: ["$HOME/.local/bin"],
});

// Its launcher entry and login autostart (Copilot's search needs it running),
// its embedding server on the GPU named by a word of its name, and no
// dashboard at login: args(miyoLauncher, "--vulkan-gpu <name>", "VAR=value"…).
export const miyoLauncher = script("miyo-launcher", {
  description: "Miyo's launcher entry and login autostart",
  managedBy: ".loadout/launcher.ts",
  runAfter: [miyo],
  later: "it launches Miyo, which is later",
});
