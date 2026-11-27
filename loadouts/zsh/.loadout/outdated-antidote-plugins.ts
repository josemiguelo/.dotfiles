// Custom `loadout machine outdated` oracle for the antidote bundles $ZDOTDIR/.zplugins
// declares. The config is the list, not the clone dirs: a declared bundle with
// no clone is a row ("not installed", candidate = its remote tip), an
// installed one is a row when its clone is behind its remote tip. antidote
// itself is a separate oracle. Silent when zsh isn't set up on this machine.
//
// `update <owner/repo>` (loadout calls it per row): clone what's missing
// with `antidote bundle`, fast-forward the one clone that's behind.
import { existsSync } from "node:fs";
import { $, type Clone, clonesBehind, fastForward, type OutdatedItem } from "loadout/script";
import { BUNDLES, antidoteInstalled, bundleAll, bundlePaths, declared } from "#antidote";

const askable = () => existsSync(BUNDLES) && antidoteInstalled();

export async function listOutdated() {
  if (!askable()) return [];
  const clones: Clone[] = [];
  const missing: OutdatedItem[] = [];
  for (const { repo, dir } of await bundlePaths()) {
    if (dir) {
      clones.push({ name: repo, dir });
      continue;
    }
    const remote = (await $`git ls-remote https://github.com/${repo} HEAD`.quiet().nothrow()).stdout.toString();
    const tip = remote.slice(0, 9).trim() || "?";
    missing.push({ item: repo, current: "-", candidate: tip, note: "not installed", link: `https://github.com/${repo}` });
  }
  return [...missing, ...(await clonesBehind(clones))];
}

export async function update(want: string) {
  if (!askable()) return;
  const dir = (await bundlePaths()).find(({ repo }) => repo === want)?.dir;
  if (dir) return fastForward({ name: want, dir });
  if (!(await declared()).includes(want)) throw new Error(`.zplugins declares no bundle '${want}'`);
  console.log(`installing ${want}`);
  await bundleAll();
}
