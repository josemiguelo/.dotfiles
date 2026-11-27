// Dotfiles REMOTE freshness: is the local chezmoi source behind its origin?
// Catches "edited dotfiles on machine A, machine B is stale". The check
// fetches at most every 6h (throttled on FETCH_HEAD's mtime) and fails soft
// offline, so `loadout machine status` can afford it; converge is a pull only -- applying the
// pulled target state is loadout's (`machine sync`, `config apply`).
import { statSync } from "node:fs";
import { $ } from "loadout/script";
import { brewPrefix } from "#brew";

// chezmoi is a brew program: only an interactive zsh has brew on PATH, and
// the converge runs from whatever shell the desktop opened (bash, first).
process.env.PATH = `${process.env.HOME}/.local/bin:${await brewPrefix()}/bin:${process.env.PATH}`;

// chezmoi owns the source location; don't hardcode it. Its sourceDir is the
// checkout: source-path is .chezmoiroot's folder (.chezmoi-home/), which only
// exists once a loadout command has built it there, never on a machine whose
// loadout is a child repo (the child builds the dotfiles' folders in its own).
const config = await $`chezmoi dump-config --format json`.quiet().nothrow();
const sourceDir = config.exitCode === 0 ? (JSON.parse(config.stdout.toString()).sourceDir ?? "") : "";
const top = await $`git -C ${sourceDir || "/nonexistent"} rev-parse --show-toplevel`
  .quiet()
  .nothrow();
const SOURCE = top.exitCode === 0 ? top.stdout.toString().trim() : "";
if (!SOURCE) {
  console.log("missing: dotfiles not initialized");
  process.exit(1);
}

/** Fetches unless FETCH_HEAD is under 6h old; offline keeps the last-known refs. */
async function fetchThrottled() {
  const fetched = statSync(`${SOURCE}/.git/FETCH_HEAD`, { throwIfNoEntry: false })?.mtimeMs;
  if (fetched === undefined || Date.now() - fetched >= 360 * 60 * 1000) {
    await $`git -C ${SOURCE} fetch -q`.quiet().nothrow();
  }
}

export async function check() {
  await fetchThrottled();
  const count = await $`git -C ${SOURCE} rev-list --count ${"HEAD..@{u}"}`.quiet().nothrow();
  const behind = count.exitCode === 0 ? Number.parseInt(count.stdout.toString(), 10) : 0;
  if (behind > 0) {
    console.log(`missing: dotfiles source is ${behind} commit(s) behind origin`);
    return false;
  }
  return true;
}

export async function install() {
  // --ff-only: a diverged source (local commits) fails visibly instead of
  // merging silently -- resolve deliberately in the source dir.
  await $`chezmoi git -- fetch -q`.quiet();
  await $`chezmoi git -- pull -q --ff-only`.quiet();
  console.log("dotfiles source up to date with origin");
}
