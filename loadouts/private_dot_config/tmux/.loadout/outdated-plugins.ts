#!/usr/bin/env bun
// Custom `loadout outdated` oracle for the tmux plugins tmux.conf declares.
// The config is the list, not the clone dirs: a declared plugin with no clone
// is a row ("not installed", candidate = its remote tip), an installed one is
// a row when its clone is behind its remote tip (lib/git-clones-behind.sh,
// shared with the zsh plugins' oracle). Silent when tmux isn't set up on this
// machine.
//
// `update <name>` (loadout calls it per row): clone what's missing with
// `tpack install`, fast-forward the one clone that's behind.
// usage: outdated-plugins.ts [update <name>]
import { existsSync } from "node:fs";
import { $, repoPath, run } from "#loadout";
import { CONF, cloneOf, declared, toolsPath } from "#tmux";

const GCB = repoPath("lib/git-clones-behind.sh");
const name = (repo: string) => repo.split("/").pop()!;

async function outdated(mode?: string, want?: string) {
  if (!existsSync(CONF)) return;
  const env = {
    ...process.env,
    PATH: await toolsPath(),
    // tpack names the clone <repo>-<12-hex-hash>; the row is named <repo>.
    GCB_NAME: 'basename "$dir" | sed "s/-[0-9a-f]\\{12\\}$//"',
  };
  if (mode === "update") {
    if (!want) throw new Error("usage: outdated-plugins.ts update <name>");
    const repo = (await declared()).find((r) => name(r) === want);
    if (!repo) throw new Error(`tmux.conf declares no plugin named '${want}'`);
    const dir = cloneOf(repo);
    if (dir) {
      await $`sh ${GCB} update ${want} ${dir}`.env(env);
    } else {
      console.log(`installing ${repo}`);
      await $`tpack install`.env(env);
    }
    return;
  }
  if (mode !== undefined) throw new Error("usage: outdated-plugins.ts [update <name>]");
  const dirs = [];
  for (const repo of await declared()) {
    const dir = cloneOf(repo);
    if (dir) {
      dirs.push(dir);
      continue;
    }
    const remote = (await $`git ls-remote https://github.com/${repo} HEAD`.quiet().nothrow()).stdout.toString();
    const tip = remote.slice(0, 9).trim() || "?";
    console.log(`${name(repo)} - ${tip} not installed https://github.com/${repo}`);
  }
  if (dirs.length > 0) await $`sh ${GCB} ${dirs}`.env(env);
}

await run(outdated);
