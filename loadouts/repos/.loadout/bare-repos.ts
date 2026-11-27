// josemiguelo's repos named by the machine (`bareRepos({ repos: ["loadout",
// "loadout.wiki"] })`), each a bare clone in ~/Repos/gh/josemiguelo/<repo> with
// its default branch checked out in all_worktrees/<branch> (#bare-repo, the
// layout `gclone --bare` makes by hand and skills-repo keeps for skills).
// Public repos: fetched over https, so a fresh machine clones them before
// GitHub knows its ssh key, and pushed over ssh. With `ssh` (private repos,
// which https can't fetch without credentials) they're fetched over ssh too. A
// leading dot is dropped from the folder's name (.dotfiles-work lands in
// dotfiles-work), so no clone is hidden. An existing clone only gets both urls
// set, and a clone left without its worktree (a clone that failed halfway)
// gets it; nothing else in it is touched.
import { mkdirSync, statSync } from "node:fs";
import { dirname } from "node:path";
import { reason } from "loadout/script";
import { addWorktree, cloneBare, defaultBranch, remotesOk, setRemotes } from "#bare-repo";
import type { Options } from "./bare-repos.rules.ts";

const HOME = process.env.HOME!;

const isDir = (path: string) => statSync(path, { throwIfNoEntry: false })?.isDirectory() ?? false;

/** Each repo's folder and remotes. */
function clones({ repos, ssh }: Options) {
  return repos.map((repo) => {
    const push = `git@github.com:josemiguelo/${repo}.git`;
    const url = ssh ? push : `https://github.com/josemiguelo/${repo}.git`;
    return { repo, dir: `${HOME}/Repos/gh/josemiguelo/${repo.replace(/^\./, "")}`, remotes: { url, push } };
  });
}

/** The default branch's worktree exists. */
async function worktreeOk(dir: string) {
  const branch = await defaultBranch(dir);
  return branch !== undefined && isDir(`${dir}/all_worktrees/${branch}`);
}

export async function check(options: Options) {
  let done = true;
  for (const { repo, dir, remotes } of clones(options)) {
    if (isDir(dir) && (await remotesOk(dir, remotes)) && (await worktreeOk(dir))) continue;
    console.log(`missing: ${repo}`);
    done = false;
  }
  return done;
}

export async function install(options: Options) {
  let failed = false;
  for (const { repo, dir, remotes } of clones(options)) {
    if (!isDir(dir)) {
      console.log(`bare-repos: cloning ${remotes.url}`);
      mkdirSync(dirname(dir), { recursive: true });
      try {
        await cloneBare(dir, remotes, "bare-repos");
      } catch (error) {
        console.error(reason(error));
        failed = true;
      }
      continue;
    }
    if (!(await remotesOk(dir, remotes))) {
      await setRemotes(dir, remotes);
      console.log(`bare-repos: ${repo} fetches from ${remotes.url}, pushes over ssh`);
    }
    if (!(await worktreeOk(dir))) {
      console.log(`bare-repos: ${repo} has no worktree for its default branch: adding it`);
      try {
        await addWorktree(dir, "bare-repos");
      } catch (error) {
        console.error(reason(error));
        failed = true;
      }
    }
  }
  if (failed) process.exit(1);
}
