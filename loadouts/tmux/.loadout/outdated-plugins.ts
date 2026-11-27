// Custom `loadout machine outdated` oracle for the tmux plugins tmux.conf declares.
// The config is the list, not the clone dirs: a declared plugin with no clone
// is a row ("not installed", candidate = its remote tip), an installed one is
// a row when its clone is behind its remote tip (clonesBehind, from
// loadout/script, as the zsh plugins' oracle). Silent when tmux isn't set up
// on this machine.
//
// `update <name>` (loadout calls it per row): clone what's missing with
// `tpack install`, fast-forward the one clone that's behind.
import { existsSync } from "node:fs";
import { $, type Clone, clonesBehind, fastForward, type OutdatedItem } from "loadout/script";
import { CONF, cloneOf, declared, toolsPath } from "#tmux";

const name = (repo: string) => repo.split("/").pop()!;

export async function listOutdated() {
  if (!existsSync(CONF)) return [];
  // tpack names the clone <repo>-<12-hex-hash>; the row is named <repo>.
  const clones: Clone[] = [];
  const missing: OutdatedItem[] = [];
  for (const repo of await declared()) {
    const dir = cloneOf(repo);
    if (dir) {
      clones.push({ name: name(repo), dir });
      continue;
    }
    const remote = (await $`git ls-remote https://github.com/${repo} HEAD`.quiet().nothrow()).stdout.toString();
    const tip = remote.slice(0, 9).trim() || "?";
    missing.push({ item: name(repo), current: "-", candidate: tip, note: "not installed", link: `https://github.com/${repo}` });
  }
  return [...missing, ...(await clonesBehind(clones))];
}

export async function update(want: string) {
  if (!existsSync(CONF)) return;
  const repo = (await declared()).find((r) => name(r) === want);
  if (!repo) throw new Error(`tmux.conf declares no plugin named '${want}'`);
  const dir = cloneOf(repo);
  if (dir) return fastForward({ name: want, dir });
  console.log(`installing ${repo}`);
  await $`tpack install`.env({ ...process.env, PATH: await toolsPath() });
}
