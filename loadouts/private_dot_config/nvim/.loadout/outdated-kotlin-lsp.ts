#!/usr/bin/env bun
// The mason-kotlin-lsp updates source: with no arguments, `kotlin-lsp
// <installed> <latest>` when Mason has a newer build; `update <item>` has
// Mason install it. Both ask mason.lua (#nvim).
// usage: outdated-kotlin-lsp.ts [update <item>]
import { run } from "#loadout";
import { masonInstall, masonOutdated } from "#nvim";

const PACKAGE = "kotlin-lsp";
const LUA = `${import.meta.dir}/mason.lua`;

await run(async (mode) => {
  if (mode === undefined) return masonOutdated(LUA, PACKAGE);
  if (mode === "update") return masonInstall(LUA, PACKAGE);
  throw new Error("usage: outdated-kotlin-lsp.ts [update <item>]");
});
