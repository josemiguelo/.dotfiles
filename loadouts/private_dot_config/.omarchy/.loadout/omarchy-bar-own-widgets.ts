#!/usr/bin/env bun
// This repo's own bar widgets, one plugin id per argument: each is
// omarchy-bar/plugins/<id>, copied whole into ~/.config/omarchy/plugins/<id>
// and enabled (where it sits is omarchy-bar-widgets'). They draw their icon
// with Omarchy's BarIconButton, so it follows the bar's icon size like every
// other.
// usage: omarchy-bar-own-widgets.ts [check] <plugin-id>...
import { existsSync, mkdtempSync } from "node:fs";
import { cp, mkdir, rename, rm } from "node:fs/promises";
import { $, fail, main, ok } from "#loadout";
import { PLUGINS, shellReady, widgetEnabled } from "#omarchy";

const SRC = `${import.meta.dir}/omarchy-bar/plugins`;

function ids(args: string[]) {
  if (args.length === 0) fail("usage: omarchy-bar-own-widgets.ts [check] <plugin-id>...");
  for (const id of args) if (!existsSync(`${SRC}/${id}/manifest.json`)) fail(`${id}: no widget at ${SRC}/${id}`);
  return args;
}

const copied = async (id: string) => existsSync(`${PLUGINS}/${id}`) && (await ok($`diff -r ${SRC}/${id} ${PLUGINS}/${id}`));

async function inPlace(args: string[]) {
  for (const id of args) if (!(await copied(id)) || !(await widgetEnabled(id))) return false;
  return true;
}

async function check(...args: string[]) {
  ids(args);
  await shellReady("check");
  return inPlace(args);
}

async function install(...args: string[]) {
  ids(args);
  await shellReady();
  let changed = false;
  await mkdir(PLUGINS, { recursive: true });
  for (const id of args) {
    if (await copied(id)) continue;
    // The folder is swapped in whole, so no file of an earlier version stays.
    const stage = mkdtempSync(`${PLUGINS}/.omarchy-bar-own-widgets.`);
    await cp(`${SRC}/${id}`, stage, { recursive: true });
    await rm(`${PLUGINS}/${id}`, { recursive: true, force: true });
    await rename(stage, `${PLUGINS}/${id}`);
    changed = true;
  }
  await $`omarchy-shell shell rescanPlugins`.quiet();
  for (const id of args) {
    for (let tries = 1; !(await widgetEnabled(id)) && !(await ok($`omarchy plugin enable ${id}`)); tries++) {
      if (tries >= 20) throw new Error(`couldn't enable ${id} (is omarchy-shell running?)`);
      await Bun.sleep(500);
    }
  }
  if (changed) {
    // A loaded plugin keeps its old QML until the shell restarts. Quickshell
    // can crash when killed mid hot-reload, so the files settle first.
    await Bun.sleep(3000);
    if (!(await ok($`omarchy restart shell`))) console.error("restart the Omarchy shell to load the new widgets (omarchy restart shell)");
    await shellReady().catch(() => {});
  }
  if (!(await inPlace(args))) throw new Error("the widgets aren't installed and enabled after install");
}

await main(check, install);
