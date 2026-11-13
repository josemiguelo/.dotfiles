#!/usr/bin/env bun
// Custom `loadout outdated` oracle for the antidote bundles $ZDOTDIR/.zplugins
// declares. The config is the list, not the clone dirs: a declared bundle with
// no clone is a row ("not installed", candidate = its remote tip), an
// installed one is a row when its clone is behind its remote tip. antidote
// itself is a separate oracle. Silent when zsh isn't set up on this machine.
//
// `update <owner/repo>` (loadout calls it per row): clone what's missing
// with `antidote bundle`, fast-forward the one clone that's behind.
// usage: outdated-antidote-plugins.ts [update <owner/repo>]
import { existsSync } from "node:fs";
import { $, clonesBehind, fastForward, formatRow, run } from "loadout/script";
import { BUNDLES, antidoteInstalled, bundleAll, bundlePaths, declared } from "#antidote";

async function outdated(mode?: string, want?: string) {
  if (!existsSync(BUNDLES) || !antidoteInstalled()) return;
  if (mode === "update") {
    if (!want) throw new Error("usage: outdated-antidote-plugins.ts update <owner/repo>");
    const dir = (await bundlePaths()).find(({ repo }) => repo === want)?.dir;
    if (dir) return fastForward({ name: want, dir });
    if (!(await declared()).includes(want)) throw new Error(`.zplugins declares no bundle '${want}'`);
    console.log(`installing ${want}`);
    await bundleAll();
    return;
  }
  if (mode !== undefined) throw new Error("usage: outdated-antidote-plugins.ts [update <owner/repo>]");
  const clones = [];
  for (const { repo, dir } of await bundlePaths()) {
    if (dir) {
      clones.push({ name: repo, dir });
      continue;
    }
    const remote = (await $`git ls-remote https://github.com/${repo} HEAD`.quiet().nothrow()).stdout.toString();
    const tip = remote.slice(0, 9).trim() || "?";
    console.log(`${repo} - ${tip} not installed https://github.com/${repo}`);
  }
  for (const row of await clonesBehind(clones)) console.log(formatRow(row));
}

await run(outdated);
