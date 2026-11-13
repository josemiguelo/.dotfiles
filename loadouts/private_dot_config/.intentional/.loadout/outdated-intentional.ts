#!/usr/bin/env bun
// Intentional's update check (intentional.ts): is the installed desktop guard
// behind the latest GitHub release?
//
//   outdated-intentional.ts          print the latest version when behind, else nothing
//   outdated-intentional.ts update   install the latest release
//
// Silent when it isn't installed or the network is down.
import { $, run } from "#loadout";

/**
 * The installed version: `intentional --version` says "intentional <version>",
 * read as `cut -d' ' -f2` reads it; "" when it isn't installed.
 */
async function current() {
  const text = (await $`intentional --version`.quiet().nothrow()).stdout.toString();
  return text
    .split("\n")
    .map((line) => (line.includes(" ") ? line.split(" ")[1] : line))
    .join("\n")
    .replace(/\n+$/, "");
}

/** The latest release's version, from where /releases/latest redirects; undefined when it can't be reached. */
async function latest() {
  try {
    const response = await fetch("https://github.com/josemiguelo/intentional/releases/latest");
    await response.body?.cancel();
    if (!response.ok) return undefined;
    const url = response.url;
    const at = url.lastIndexOf("/v");
    return at < 0 ? url : url.slice(at + 2);
  } catch {
    return undefined;
  }
}

async function outdated(mode?: string) {
  // Exits as the installer does, its output already shown.
  if (mode === "update") process.exit((await $`${`${import.meta.dir}/intentional.ts`} install`.nothrow()).exitCode);
  if (mode !== undefined) throw new Error("usage: outdated-intentional.ts [update]");
  const cur = await current();
  if (!cur) return;
  const now = await latest();
  if (now && now !== cur) console.log(now);
}

await run(outdated);
