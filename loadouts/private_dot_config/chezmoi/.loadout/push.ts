#!/usr/bin/env bun
// Dotfiles OUTBOUND freshness: is this machine sitting on dotfiles changes
// the fleet can't see? The mirror of dotfiles-pull -- pull watches what origin
// has that we don't, this watches what we have that origin doesn't:
// uncommitted edits in the chezmoi source, or committed-but-unpushed work.
// Check is local-only (no fetch, instant). Converge pushes when the source
// is clean and ahead; a dirty source fails visibly -- writing the commit is a
// human decision, never automated. Modes: `check` / `install` (default).
import { $, brewPrefix, main } from "#loadout";

// Anything but `check` or `install` is a usage error (exit 2): main would take
// it for install's argument.
const mode = Bun.argv[2] ?? "install";
if (mode !== "check" && mode !== "install") {
  console.error(`usage: ${Bun.argv[1]} [check|install]`);
  process.exit(2);
}

// chezmoi is a brew program: only an interactive zsh has brew on PATH, and
// the converge runs from whatever shell the desktop opened (bash, first).
process.env.PATH = `${process.env.HOME}/.local/bin:${await brewPrefix()}/bin:${process.env.PATH}`;

// chezmoi owns the source location; don't hardcode it. The source path is
// .chezmoiroot's folder, so the repo is the git top level above it.
const sourcePath = await $`chezmoi source-path`.quiet().nothrow();
const top = await $`git -C ${sourcePath.exitCode === 0 ? sourcePath.stdout.toString().trim() : "/nonexistent"} rev-parse --show-toplevel`
  .quiet()
  .nothrow();
const SOURCE = top.exitCode === 0 ? top.stdout.toString().trim() : "";
if (!SOURCE) {
  console.log("missing: dotfiles not initialized");
  process.exit(1);
}

// Uncommitted changes (0 when git can't tell) and commits origin hasn't seen.
const status = await $`git -C ${SOURCE} status --porcelain`.quiet().nothrow();
const dirty = status.stdout.toString().split("\n").filter(Boolean).length;
const count = await $`git -C ${SOURCE} rev-list --count ${"@{u}..HEAD"}`.quiet().nothrow();
const ahead = count.exitCode === 0 ? Number.parseInt(count.stdout.toString(), 10) : 0;

function ready() {
  if (dirty > 0) {
    console.log(`missing: ${dirty} uncommitted change(s) in the dotfiles source`);
    return false;
  }
  if (ahead > 0) {
    console.log(`missing: dotfiles source is ${ahead} commit(s) ahead of origin — push them`);
    return false;
  }
  return true;
}

async function install() {
  if (dirty > 0) {
    console.error(`dotfiles source has ${dirty} uncommitted change(s) — commit them yourself:`);
    process.stderr.write((await $`git -C ${SOURCE} status --short`.quiet().nothrow()).stdout);
    process.exit(1);
  }
  if (ahead > 0) {
    await $`chezmoi git -- push -q`.quiet();
    console.log(`pushed ${ahead} commit(s) to origin`);
  } else {
    console.log("nothing to push");
  }
}

await main(ready, install);
