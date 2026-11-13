#!/usr/bin/env bun
// Custom `loadout outdated` oracle for Omarchy shell plugins installed from
// git (~/.config/omarchy/plugins/<id>, a clone each): a row per plugin whose
// clone is behind its remote's HEAD, named by the plugin id. Silent when no
// plugin is installed.
//
// `update <id>` (loadout calls it per row) is Omarchy's own `omarchy plugin
// update <id> --yes`: it fast-forwards, validates (rolling back a failure)
// and reloads the shell's plugins.
//
// A clone with commits of its own (a local patch on a branch) or uncommitted
// changes can't be fast-forwarded: its row says so ("diverged: …"), and
// `update` refuses it, naming what's in the way, instead of letting
// omarchy-plugin-update fail on it.
import { existsSync } from "node:fs";
import { basename } from "node:path";
import { $, clonesBehind, fail, formatRow } from "loadout/script";
import { PLUGINS, pluginCheckouts, pluginDiverged } from "#omarchy";

const [mode, id] = Bun.argv.slice(2);
if (mode === "update") {
  if (!id) fail("usage: outdated-plugins.ts update <id>");
  const dir = `${PLUGINS}/${id}`;
  if (!existsSync(`${dir}/.git`)) fail(`no git-managed plugin '${id}'`);
  await $`git -C ${dir} fetch --quiet origin HEAD`;
  const why = await pluginDiverged(dir);
  if (why) fail(`${id} has ${why}: \`omarchy plugin update\` can't fast-forward ${dir}; bring it up to date by hand`);
  process.exit((await $`omarchy plugin update ${id} --yes`.nothrow()).exitCode);
}

// Each row named by the folder, which is the plugin id. clonesBehind leaves
// each clone's FETCH_HEAD at its remote's HEAD, which pluginDiverged compares
// against.
const rows = await clonesBehind(pluginCheckouts().map((dir) => ({ name: basename(dir), dir })));
for (const row of rows) {
  const why = await pluginDiverged(`${PLUGINS}/${row.item}`);
  console.log(`${formatRow(row)}${why ? ` diverged: ${why}, update by hand` : ""}`);
}
