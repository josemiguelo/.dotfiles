// Clones that track their remote's default branch, for `loadout outdated`
// oracles: which are behind their remote's HEAD, and fast-forwarding one.
import { existsSync } from "node:fs";
import { $ } from "#loadout";

/** A clone and the name its row goes by. */
export type Clone = { name: string; dir: string };

/** Its output, trimmed, or undefined when it fails. */
async function git(dir: string, ...args: string[]) {
  const result = await $`git -C ${dir} ${args}`.quiet().nothrow();
  return result.exitCode === 0 ? result.stdout.toString().trim() : undefined;
}

/** https://github.com/owner/repo for a GitHub origin (ssh or https), else undefined. */
async function githubOf(dir: string) {
  const url = await git(dir, "remote", "get-url", "origin");
  const m = url?.match(/^(?:git@github\.com:|https:\/\/github\.com\/)([^/]+\/[^/]+?)(?:\.git)?$/);
  return m ? `https://github.com/${m[1]}` : undefined;
}

/**
 * The row of a clone whose HEAD is behind its remote's: "<name> <head> <tip>
 * N commit(s) behind", the shas cut to 9. undefined when it's up to date,
 * provably ahead (a pin on a non-default branch), or its fetch fails. A
 * shallow clone still compares shas, without the count. A GitHub origin adds
 * the compare page of the two shas, which loadout offers under K. Leaves
 * FETCH_HEAD at the remote's HEAD.
 */
async function rowOf({ name, dir }: Clone) {
  const head = await git(dir, "rev-parse", "HEAD");
  if (!head || (await git(dir, "fetch", "-q", "origin", "HEAD")) === undefined) return undefined;
  const tip = await git(dir, "rev-parse", "FETCH_HEAD");
  if (!tip || tip === head) return undefined;
  const behind = await git(dir, "rev-list", "--count", `${head}..FETCH_HEAD`);
  if (behind === "0") return undefined;
  const github = await githubOf(dir);
  const note = [
    behind && `${behind} commit(s) behind`,
    github && `${github}/compare/${head.slice(0, 9)}...${tip.slice(0, 9)}`,
  ].filter(Boolean);
  return [name, head.slice(0, 9), tip.slice(0, 9), ...note].join(" ");
}

/** A row per clone that's behind, sorted; all fetched at once. What isn't a clone is skipped. */
export async function behind(clones: Clone[]): Promise<string[]> {
  const rows = await Promise.all(clones.filter(({ dir }) => existsSync(`${dir}/.git`)).map(rowOf));
  return rows.filter((row): row is string => row !== undefined).sort();
}

/** Fast-forwards the clone to its remote; one that can't fails rather than rewriting history. */
export async function fastForward({ name, dir }: Clone) {
  if (!existsSync(`${dir}/.git`)) throw new Error(`no clone named '${name}' here`);
  console.log(`updating ${name} (${dir})`);
  await $`git -C ${dir} pull --ff-only`;
}
