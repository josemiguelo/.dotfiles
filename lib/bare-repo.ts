// Bare clones with their default branch checked out in all_worktrees/<branch>,
// the layout `gclone --bare` (repos.plugin.zsh) makes by hand, for bare-repos
// and skills-repo: fetched from one url (https for a public repo, so a fresh
// machine clones it before GitHub knows its ssh key) and pushed to another
// (ssh, remote.origin.pushurl).
import { $ } from "loadout/script";

/** Where a clone fetches from and pushes to. */
export type Remotes = { url: string; push: string };

/** Its output, trimmed, or undefined when it fails. */
async function git(dir: string, ...args: string[]) {
  const result = await $`git -C ${dir} ${args}`.quiet().nothrow();
  return result.exitCode === 0 ? result.stdout.toString().trim() : undefined;
}

/** The branch the bare repo's HEAD names: its default branch. */
export const defaultBranch = (dir: string) => git(dir, "symbolic-ref", "--quiet", "--short", "HEAD");

/** origin fetches from url and pushes to push. */
export const remotesOk = async (dir: string, { url, push }: Remotes) =>
  (await git(dir, "config", "--get", "remote.origin.url")) === url &&
  (await git(dir, "config", "--get", "remote.origin.pushurl")) === push;

export async function setRemotes(dir: string, { url, push }: Remotes) {
  await $`git -C ${dir} config remote.origin.url ${url}`.quiet();
  await $`git -C ${dir} config remote.origin.pushurl ${push}`.quiet();
}

/**
 * A bare clone of remotes.url in dir and its default branch's worktree,
 * tracking origin. `git clone --bare` leaves remote.origin.fetch unset, unlike
 * a plain clone, so a later fetch would silently fetch nothing; it's set here
 * as gclone --bare does. who names the script in its error.
 */
export async function cloneBare(dir: string, remotes: Remotes, who: string) {
  await $`git clone --quiet --bare -- ${remotes.url} ${dir}`.quiet();
  await setRemotes(dir, remotes);
  await $`git -C ${dir} config remote.origin.fetch ${"+refs/heads/*:refs/remotes/origin/*"}`.quiet();
  await $`git -C ${dir} fetch --quiet --prune origin`.quiet().nothrow();
  const branch = await defaultBranch(dir);
  if (!branch) throw new Error(`${who}: no default branch in ${dir}`);
  const worktree = `${dir}/all_worktrees/${branch}`;
  await $`git -C ${dir} worktree add --quiet ${worktree} ${branch}`.quiet();
  await $`git -C ${worktree} branch --quiet --set-upstream-to=${`origin/${branch}`} ${branch}`.quiet().nothrow();
}
