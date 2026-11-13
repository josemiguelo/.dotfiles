#!/usr/bin/env bun
// Default packages (~/.default-npm-packages and ~/.default-gems) present in
// EVERY node and ruby version ~/.config/mise/config.toml pins. mise only seeds
// them into versions it installs from then on, so packages added later need
// this backfill into the versions that already exist.
// Modes: `check` / `install` (default).
// One `npm ls` / `gem list` query per tool version (not per package), run
// concurrently up front — npm boots a node each.
import { existsSync } from "node:fs";
import { $, main, out, read } from "loadout/script";

const HOME = process.env.HOME!;
const NPM = `${HOME}/.default-npm-packages`;
const GEMS = `${HOME}/.default-gems`;

/** The installed versions the global config pins for a tool; missing ones are mise-tools' business, not this one's. */
async function versionsOf(tool: string) {
  const listed = await $`mise ls --global ${tool}`.cwd(HOME).quiet().nothrow();
  if (listed.exitCode !== 0) throw new Error(`mise could not list ${tool}'s versions`);
  return listed.stdout
    .toString()
    .split("\n")
    .map((l) => l.trim().split(/\s+/))
    .filter((f) => f.length >= 2 && f[0] && f[2] !== "(missing)")
    .map((f) => f[1]);
}

/** A packages file's names: first word per line, comments and blank lines skipped. */
const packagesIn = async (file: string) =>
  (await read(file))
    .split("\n")
    .map((l) => l.trim().split(/\s+/)[0])
    .filter((p) => p && !p.startsWith("#"));

type Gap = { tool: "node" | "ruby"; version: string; pkg: string };

/**
 * Every default package missing from a version, from one `npm ls` / `gem
 * list` per version (not per package), asked concurrently: npm boots a node
 * each. Listed up front: mise failing would otherwise list no versions, and a
 * check over no versions passes.
 */
async function gaps(): Promise<Gap[]> {
  const asks: Promise<Gap[]>[] = [];
  if (existsSync(NPM)) {
    const pkgs = await packagesIn(NPM);
    for (const v of await versionsOf("node")) {
      asks.push(
        $`mise exec ${`node@${v}`} -- npm ls -g --depth=0 --parseable`.cwd(HOME).quiet().nothrow().then((r) => {
          const have = r.stdout.toString().split("\n");
          return pkgs.filter((p) => !have.some((l) => l.endsWith(`/${p}`))).map((pkg) => ({ tool: "node", version: v, pkg }));
        }),
      );
    }
  }
  if (existsSync(GEMS)) {
    const pkgs = await packagesIn(GEMS);
    for (const v of await versionsOf("ruby")) {
      asks.push(
        $`mise exec ${`ruby@${v}`} -- gem list --no-versions`.cwd(HOME).quiet().nothrow().then((r) => {
          const have = r.stdout.toString().split("\n");
          return pkgs.filter((p) => !have.includes(p)).map((pkg) => ({ tool: "ruby", version: v, pkg }));
        }),
      );
    }
  }
  return (await Promise.all(asks)).flat();
}

async function ready() {
  const missing = await gaps();
  for (const g of missing) console.log(`missing: ${g.tool} ${g.version} ${g.tool === "node" ? "npm" : "gem"} ${g.pkg}`);
  return missing.length === 0;
}

async function install() {
  for (const g of await gaps()) {
    console.log(`installing ${g.pkg} for ${g.tool} ${g.version}`);
    if (g.tool === "node") await $`mise exec ${`node@${g.version}`} -- npm install -g ${g.pkg}`.cwd(HOME);
    else await $`mise exec ${`ruby@${g.version}`} -- gem install ${g.pkg}`.cwd(HOME);
  }
}

await main(ready, install);
