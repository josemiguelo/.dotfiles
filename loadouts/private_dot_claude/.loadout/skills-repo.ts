#!/usr/bin/env bun
// Keeps ~/Repos/gh/josemiguelo/skills cloned (bare + worktree, #bare-repo) and
// symlinks each skill it contains into ~/.claude/skills/<name> -- individually,
// not as one directory-level symlink over ~/.claude/skills itself: tools like
// `workmux setup --skills` write their own regenerable skills directly into
// ~/.claude/skills, and a blanket symlink would redirect that regenerable
// content into this tracked repo.
//
// The repo is public: it's fetched over https, so a fresh machine clones it
// before GitHub knows its ssh key, and pushed over ssh (remote.origin.pushurl).
// An existing checkout gets both urls set too.
//
// Modes: `check` / `install` (default).
import { existsSync, lstatSync, mkdirSync, readdirSync, readlinkSync, rmSync, statSync, symlinkSync } from "node:fs";
import { $, main } from "#loadout";
import { cloneBare, defaultBranch, remotesOk, setRemotes } from "#bare-repo";

const HOME = process.env.HOME!;
const REMOTES = { url: "https://github.com/josemiguelo/skills.git", push: "git@github.com:josemiguelo/skills.git" };
const REPO = `${HOME}/Repos/gh/josemiguelo/skills`;
const SKILLS_DIR = `${HOME}/.claude/skills`;

const isDir = (path: string) => statSync(path, { throwIfNoEntry: false })?.isDirectory() ?? false;
const isLink = (path: string) => lstatSync(path, { throwIfNoEntry: false })?.isSymbolicLink() ?? false;

/**
 * The default branch's worktree specifically -- not just whichever one `git
 * worktree list` happens to print first. A feature worktree can exist
 * alongside it (in-progress work, not yet merged back), and symlinks must
 * always converge on the default branch's content, never on whatever feature
 * worktree happens to exist at the time. "" when there's none.
 */
async function worktreePath() {
  const branch = await defaultBranch(REPO);
  if (!branch) return "";
  const list = await $`git -C ${REPO} worktree list --porcelain`.quiet().nothrow();
  let path = "";
  for (const line of list.stdout.toString().split("\n")) {
    if (line.startsWith("worktree ")) path = line.slice("worktree ".length);
    else if (line === `branch refs/heads/${branch}`) return path;
  }
  return "";
}

/** Every top-level skill directory the worktree has. */
function skillNames(wt: string) {
  if (!isDir(wt)) return [];
  return readdirSync(wt, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && entry.name !== ".git")
    .map((entry) => entry.name);
}

/**
 * Links in SKILLS_DIR into the worktree whose skill is gone from it (removed
 * or renamed in the repo). Only links into this repo's worktree: Omarchy's
 * links and the folders other tools write are never ours.
 */
function staleLinks(wt: string) {
  let names: string[];
  try {
    names = readdirSync(SKILLS_DIR).filter((name) => !name.startsWith(".")).sort();
  } catch {
    return [];
  }
  return names
    .map((name) => `${SKILLS_DIR}/${name}`)
    .filter((link) => isLink(link) && readlinkSync(link).startsWith(`${wt}/`) && !existsSync(link));
}

async function ready() {
  if (!isDir(REPO) || !(await remotesOk(REPO, REMOTES))) return false;
  const wt = await worktreePath();
  if (!wt || staleLinks(wt).length > 0) return false;
  return skillNames(wt).every((name) => {
    const link = `${SKILLS_DIR}/${name}`;
    return isLink(link) && readlinkSync(link) === `${wt}/${name}`;
  });
}

async function install() {
  if (!isDir(REPO)) {
    console.log(`skills-repo: cloning ${REMOTES.url}`);
    await cloneBare(REPO, REMOTES, "skills-repo");
  } else if (!(await remotesOk(REPO, REMOTES))) {
    await setRemotes(REPO, REMOTES);
    console.log("skills-repo: origin fetches over https, pushes over ssh");
  }

  const wt = await worktreePath();
  if (!wt) throw new Error(`skills-repo: ${REPO} has no worktree -- clone it manually first`);

  mkdirSync(SKILLS_DIR, { recursive: true });
  for (const link of staleLinks(wt)) {
    rmSync(link);
    console.log(`skills-repo: unlinked ${link.slice(SKILLS_DIR.length + 1)} (gone from the repo)`);
  }
  for (const name of skillNames(wt)) {
    const link = `${SKILLS_DIR}/${name}`;
    const target = `${wt}/${name}`;
    if (isLink(link)) {
      if (readlinkSync(link) !== target) {
        rmSync(link);
        symlinkSync(target, link);
        console.log(`skills-repo: relinked ${name}`);
      }
    } else if (existsSync(link)) {
      console.error(`skills-repo: ${link} exists and isn't a symlink; leaving it`);
    } else {
      symlinkSync(target, link);
      console.log(`skills-repo: linked ${name}`);
    }
  }
}

// Anything but `check` or `install` is a usage error (exit 2): main would take
// it for install's argument.
const mode = Bun.argv[2] ?? "install";
if (mode !== "check" && mode !== "install") {
  console.error(`usage: ${Bun.argv[1]} [check|install]`);
  process.exit(2);
}

await main(ready, install);
