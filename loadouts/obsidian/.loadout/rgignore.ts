// What an unscoped ripgrep in a vault skips: <vault>/.rgignore. Agent Chat's
// grep (OpenCode's, ripgrep with --hidden) otherwise reads Copilot's own
// main.js and chat logs, ~90% of what a search returned (docs/local-llm.md).
// A search that names one of these folders still reads it, as does read.
// check: every pattern is a line of the file. install: adds the missing ones,
// leaving the file's other lines alone.
import { existsSync } from "node:fs";
import { fail, read } from "loadout/script";
import { vaultPath } from "#obsidian";
import type { Options } from "./rgignore.rules.ts";

function wanted({ vault, patterns }: Options) {
  const root = vaultPath(vault);
  return { root, file: `${root}/.rgignore`, patterns };
}

async function missing(file: string, patterns: string[]) {
  const lines = ((await read(file)) ?? "").split("\n").map((l) => l.trim());
  return patterns.filter((p) => !lines.includes(p));
}

export async function check(options: Options) {
  const { file, patterns } = wanted(options);
  return (await missing(file, patterns)).length === 0;
}

export async function install(options: Options) {
  const { root, file, patterns } = wanted(options);
  // obsidian-vault, which runs first, waits for Sync to bring it.
  if (!existsSync(`${root}/.obsidian`)) fail(`${root} isn't there yet: run obsidian-vault first`);
  const text = (await read(file)) ?? "";
  const kept = text && !text.endsWith("\n") ? `${text}\n` : text;
  const added = (await missing(file, patterns)).map((p) => `${p}\n`);
  await Bun.write(file, kept + added.join(""));
}
