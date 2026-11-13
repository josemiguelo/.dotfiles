#!/usr/bin/env bun
// Global git identity + delta/merge config. Name and email are the same on
// every machine, the email GitHub's noreply address: this repo is public, and
// commits carry it. What one machine needs on top, a work email for its work
// repos say, goes in ~/.gitconfig.local, which this file includes last (so it
// wins) and which never enters the repo; git skips the include while it
// doesn't exist. E.g. on the work machine:
//   [includeIf "gitdir:~/Work/"]
//       path = ~/.gitconfig-work   # [user] email = <work address>
//
// Written to ~/.gitconfig by name, never with `--global`: that writes to
// ~/.config/git/config whenever ~/.gitconfig doesn't exist yet — on Omarchy
// that's Omarchy's own file, which `omarchy-reinstall-configs` puts back to
// its defaults. git reads both, and ~/.gitconfig wins a key they share.
//
// Read by name too: once ~/.gitconfig exists, `git config --global` reads
// ONLY that file, so Omarchy's identity in ~/.config/git/config would look
// unset and get overwritten.
// Modes: `check` / `install` (default).
import { $, main } from "loadout/script";

const DESIRED_EMAIL = "15330034+josemiguelo@users.noreply.github.com";
const DESIRED_NAME = "Jose Miguel Ochoa";
const HOME = process.env.HOME!;
const GITCONFIG = `${HOME}/.gitconfig`;
const LOCAL = "~/.gitconfig.local";
const XDG_GITCONFIG = `${process.env.XDG_CONFIG_HOME || `${HOME}/.config`}/git/config`;

/** A key's values in one file, as `$(git config …)` reads them; undefined when it has none. */
async function fileGet(file: string, ...args: string[]) {
  const got = await $`git config --file ${file} ${args}`.quiet().nothrow();
  return got.exitCode === 0 ? got.stdout.toString().replace(/\n+$/, "") : undefined;
}

/** A key's global value as git itself resolves it: ~/.gitconfig first. */
const globalGet = async (key: string) =>
  (await fileGet(GITCONFIG, "--get", key)) ?? (await fileGet(XDG_GITCONFIG, "--get", key)) ?? "";

/** ~/.gitconfig includes ~/.gitconfig.local. */
const includesLocal = async () => ((await fileGet(GITCONFIG, "--get-all", "include.path")) ?? "").split("\n").includes(LOCAL);

async function ready() {
  return (
    (await globalGet("user.email")) === DESIRED_EMAIL &&
    (await globalGet("user.name")) === DESIRED_NAME &&
    (await globalGet("core.pager")) === "delta" &&
    (await globalGet("merge.conflictStyle")) === "zdiff3" &&
    (await includesLocal())
  );
}

async function install(...args: string[]) {
  // main reads any first argument but check as install's; the sh refused it.
  if (args[0] !== undefined) {
    console.error("usage: setup-git.ts [check|install]");
    process.exit(2);
  }
  // In ~/.gitconfig even when Omarchy's installer set others: these win.
  await $`git config --file ${GITCONFIG} user.email ${DESIRED_EMAIL}`;
  await $`git config --file ${GITCONFIG} user.name ${DESIRED_NAME}`;
  await $`git config --file ${GITCONFIG} core.pager delta`;
  await $`git config --file ${GITCONFIG} interactive.diffFilter ${"delta --color-only"}`;
  await $`git config --file ${GITCONFIG} delta.navigate true`;
  await $`git config --file ${GITCONFIG} merge.conflictStyle zdiff3`;
  // Added after the identity, so it lands below it: an include's values win
  // only over what comes before it.
  if (!(await includesLocal())) await $`git config --file ${GITCONFIG} --add include.path ${LOCAL}`;
}

await main(ready, install);
