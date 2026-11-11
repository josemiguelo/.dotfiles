#!/usr/bin/env bun
// tmux plugins, exactly the `set -g @plugin` lines in tmux.conf declare (the
// file comes from the chezmoi dotfiles). tpack keeps no lockfile, so the
// check is presence: EVERY declared plugin has a clone. Whether a clone is
// behind its remote is the tmux-plugins oracle's question
// (outdated-plugins.ts), not this one's.
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { $, main } from "#loadout";
import { CONF, cloneOf, declared, toolsPath } from "#tmux";

async function ready() {
  if (!existsSync(CONF)) {
    console.error("tmux.conf not found");
    return false;
  }
  const missing = (await declared()).filter((repo) => !cloneOf(repo));
  for (const repo of missing) console.log(`missing plugin: ${repo}`);
  return missing.length === 0;
}

async function install() {
  const PATH = await toolsPath();
  if (!Bun.which("tpack", { PATH })) throw new Error("tpack not found");
  await $`tpack install`.env({ ...process.env, PATH });
}

await main(ready, install);
