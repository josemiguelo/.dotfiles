// Agent Chat's OpenCode in a vault, sized for a small local model
// (docs/local-llm.md): <vault>/.opencode/opencode.json, a project config, so
// only the OpenCode that Copilot runs in the vault reads it (~/.config/opencode
// is the shells' opencode's too).
//   - compaction: OpenCode keeps 16000 tokens free below the context window
//     and 15000 of conversation, sizes for big models: at 32K it compacted at
//     16.8K, barely past its own setup prompt;
//   - skills: only the named ones. Every skill in ~/.claude and ~/.agents is
//     otherwise in the setup prompt, a third of it, and changing one makes the
//     warm-up's copy stale.
// check: those keys as the arguments make them. install: writes them, leaving
// the file's other keys alone; OpenCode reads them when it next starts.
import { existsSync, mkdirSync } from "node:fs";
import { fail, read } from "loadout/script";
import { vaultPath } from "#obsidian";
import type { Options } from "./opencode.rules.ts";

type Permission = { action: string; resource: string; effect: string };
type Config = { compaction?: unknown; permissions?: Permission[] } & Record<string, unknown>;

function wanted({ vault, buffer, keep, skills }: Options) {
  const root = vaultPath(vault);
  return {
    root,
    file: `${root}/.opencode/opencode.json`,
    compaction: { buffer, keep: { tokens: keep } },
    // The last match wins.
    skills: [
      { action: "skill", resource: "*", effect: "deny" },
      ...skills.map((resource) => ({ action: "skill", resource, effect: "allow" })),
    ],
  };
}

async function config(file: string): Promise<Config> {
  const text = await read(file);
  return text ? JSON.parse(text) : {};
}

const skillRules = (c: Config) => (c.permissions ?? []).filter((p) => p.action === "skill");

export async function check(options: Options) {
  const { file, compaction, skills } = wanted(options);
  const c = await config(file);
  return Bun.deepEquals(c.compaction, compaction) && Bun.deepEquals(skillRules(c), skills);
}

export async function install(options: Options) {
  const { root, file, compaction, skills } = wanted(options);
  // obsidian-vault, which runs first, waits for Sync to bring it.
  if (!existsSync(`${root}/.obsidian`)) fail(`${root} isn't there yet: run obsidian-vault first`);
  const c = await config(file);
  const permissions = [...(c.permissions ?? []).filter((p) => p.action !== "skill"), ...skills];
  mkdirSync(`${root}/.opencode`, { recursive: true });
  await Bun.write(file, `${JSON.stringify({ ...c, compaction, permissions }, null, 2)}\n`);
}
