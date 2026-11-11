#!/usr/bin/env bun
// The nvim-plugins updates source: with no arguments, the plugins Lazy calls
// outdated (`<plugin> <current> <candidate>` lines, honouring each plugin's
// version/tag/commit/branch/pin); `update <plugin>` moves one, through Lazy, so
// Lazy stays the only writer of the pins. Both ask plugins.lua (#nvim).
// usage: outdated-plugins.ts [update <plugin>]
import { run } from "#loadout";
import { lazyOutdated, lazyUpdate } from "#nvim";

const LUA = `${import.meta.dir}/plugins.lua`;

async function outdated(mode?: string, plugin?: string) {
  if (mode === undefined) return lazyOutdated(LUA);
  if (mode === "update" && plugin) return lazyUpdate(LUA, plugin);
  throw new Error("usage: outdated-plugins.ts [update <plugin>]");
}

await run(outdated);
