#!/usr/bin/env bun
// Custom `loadout outdated` oracle: are the pins in ~/.config/mise/config.toml
// behind upstream WITHIN THEIR MAJOR? Only each tool's primary (first) pin,
// compared against its own major line — ruby 3.4.8 against 3.x, never 4.x;
// java's "major" is its vendor+major
// (temurin-21). Crossing a major is a decision, not an update. Moving targets
// (latest, nightly, stable) stay silent — `omarchy update` / `mise up` move
// the "latest" ones.
//
// `update <tool>` is the other half (loadout calls it per row): install the
// newest version on that line and make it the primary pin, leaving the older
// versions listed. The pin is rewritten in place, not with `mise config set`,
// which drops the comment above the key. The file is the dotfiles' — bring the
// change back into the repo afterwards with `chezmoi re-add`.
// usage: outdated-tools.ts [update <tool>]
import { existsSync, statSync } from "node:fs";
import { readFile, writeFile } from "node:fs/promises";
import { $, has, run } from "#loadout";

const HOME = process.env.HOME!;
const CFG = process.env.MISE_GLOBAL_CONFIG_FILE || `${process.env.XDG_CONFIG_HOME || `${HOME}/.config`}/mise/config.toml`;
const MOVING = new Set(["latest", "nightly", "stable", "lts", "system", ""]);
const PRERELEASE = /(-src|-dev|-latest|-stm|[-.]rc|-milestone|-alpha|-beta|[-.]pre|-next|(a|b|c)[0-9]+|snapshot|master|nightly)/i;

/**
 * [tool, primary pin] per [tools] entry, in file order; stops at the first
 * table (a tool with options, e.g. cocoapods = { os = ... }). Every mise
 * command runs from $HOME, where mise reads the global config only.
 */
async function pins(): Promise<[string, string][]> {
  const got = await $`mise config get -f ${CFG} tools`.cwd(HOME).quiet().nothrow();
  const found: [string, string][] = [];
  for (const line of got.stdout.toString().split("\n")) {
    if (line.startsWith("[")) break;
    const m = /^"?([^"= ]*)"? = \[?"([^"]*)".*/.exec(line);
    if (m) found.push([m[1], m[2]]);
  }
  return found;
}

/** Everything before the first dot. */
const majorOf = (pin: string) => pin.split(".")[0];

/**
 * Latest stable version on the pin's major line: the "major" matched
 * ANCHORED against mise's full list (a prefix query would take tomcat 9 to
 * 10.x). Pre-releases dropped; ordered by `sort -V`, as the sh did, so the
 * newest is the one this OS's sort calls newest. "" when there's none.
 */
async function latestInMajor(tool: string, pin: string) {
  const line = new RegExp(`^${majorOf(pin).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\.`);
  const sorted = await $`mise ls-remote ${tool} | sort -V`.cwd(HOME).quiet().nothrow();
  return (
    sorted.stdout
      .toString()
      .split("\n")
      .filter((v) => line.test(v) && !PRERELEASE.test(v))
      .at(-1) ?? ""
  );
}

/**
 * Swaps the first "<old>" on the tool's own line (`<tool> = …` or
 * `"<tool>" = …`) for "<next>"; everything else stays, written back into the
 * same file (its link and mode kept).
 */
async function repin(tool: string, old: string, next: string) {
  const lines = (await readFile(CFG, "utf8")).split("\n");
  if (lines.at(-1) === "") lines.pop();
  const at = lines.findIndex((l) => {
    const [first, second] = l.trim().split(/[ \t]+/);
    return (first === tool || first === `"${tool}"`) && second === "=" && l.includes(`"${old}"`);
  });
  if (at >= 0) lines[at] = lines[at].replace(`"${old}"`, () => `"${next}"`);
  await writeFile(CFG, lines.map((l) => `${l}\n`).join(""));
}

async function update(tool?: string) {
  if (!tool) throw new Error("usage: outdated-tools.ts update <tool>");
  const pin = (await pins()).find(([t]) => t === tool)?.[1];
  if (!pin) throw new Error(`no pin for '${tool}' in ${CFG}`);
  const latest = await latestInMajor(tool, pin);
  if (!latest) throw new Error(`mise lists nothing on ${majorOf(pin)}.x for '${tool}'`);
  if (latest === pin) return console.log(`${tool} already pinned to ${latest}`);
  await $`mise install ${`${tool}@${latest}`}`.cwd(HOME);
  await repin(tool, pin, latest);
  console.log(`${tool} pinned to ${latest} (was ${pin})`);
}

/**
 * "<tool> <pin> <latest>" per pin that's behind, asked concurrently, ordered
 * by tool name as the sh's one file per tool (named with / and : as _) was.
 */
async function behind() {
  const rows = new Map<string, string>();
  const asks = (await pins())
    .filter(([, pin]) => !MOVING.has(pin) && !pin.startsWith("ref:"))
    .map(async ([tool, pin]) => [tool, pin, await latestInMajor(tool, pin)] as const);
  for (const [tool, pin, latest] of await Promise.all(asks)) {
    if (latest && latest !== pin) rows.set(tool.replace(/[/:]/g, "_"), `${tool} ${pin} ${latest}`);
  }
  for (const key of [...rows.keys()].sort()) console.log(rows.get(key));
}

async function outdated(mode?: string, tool?: string) {
  // Nothing to ask with: say nothing (a non-zero exit would read as a failure).
  if (!has("mise") || !existsSync(CFG) || !statSync(CFG).isFile()) return;
  if (mode === "update") return update(tool);
  await behind();
}

await run(outdated);
