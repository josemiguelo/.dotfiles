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
import { $, fail } from "#loadout";
import { PLUGINS, pluginCheckouts, pluginDiverged } from "#omarchy";

const GCB = `${process.env.LOADOUT_REPO}/lib/git-clones-behind.sh`;

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

const dirs = pluginCheckouts();
if (dirs.length === 0) process.exit(0);
// git-clones-behind names each row by the folder, which is the plugin id, and
// leaves each clone's FETCH_HEAD at its remote's HEAD, which pluginDiverged
// compares against.
const rows = (await $`sh ${GCB} ${dirs}`.env({ ...process.env, GCB_NAME: 'basename "$dir"' }).text()).trim();
for (const row of rows ? rows.split("\n") : []) {
  const [name, ...rest] = row.split(" ");
  const why = await pluginDiverged(`${PLUGINS}/${basename(name)}`);
  console.log(`${name} ${rest.join(" ")}${why ? ` diverged: ${why}, update by hand` : ""}`);
}
