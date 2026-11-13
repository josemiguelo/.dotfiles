import { brewCask, program } from "loadout";

// OpenAI's Codex CLI: a cask on macOS; on Omarchy it comes from mise, so it
// isn't mapped there.
export const codex = program("codex", { description: "OpenAI Codex CLI", install: [brewCask] });
