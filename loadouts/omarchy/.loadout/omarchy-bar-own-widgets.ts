// This repo's own bar widgets, by id: each is
// omarchy-bar/plugins/<id>, copied whole into ~/.config/omarchy/plugins/<id>
// and enabled (where it sits is omarchy-bar-widgets'). They draw their icon
// with Omarchy's BarIconButton, so it follows the bar's icon size like every
// other.
import { existsSync, mkdtempSync } from "node:fs";
import { cp, mkdir, rename, rm } from "node:fs/promises";
import { $, fail, succeeds } from "loadout/script";
import { PLUGINS, shellReady, widgetEnabled } from "#omarchy";
import type { Options } from "./omarchy-bar-own-widgets.rules.ts";
import { tell } from "#user";

const SRC = `${import.meta.dir}/omarchy-bar/plugins`;

function known(ids: string[]) {
  for (const id of ids) if (!existsSync(`${SRC}/${id}/manifest.json`)) fail(`${id}: no widget at ${SRC}/${id}`);
}

const copied = async (id: string) => existsSync(`${PLUGINS}/${id}`) && (await succeeds($`diff -r ${SRC}/${id} ${PLUGINS}/${id}`));

async function inPlace(ids: string[]) {
  for (const id of ids) if (!(await copied(id)) || !(await widgetEnabled(id))) return false;
  return true;
}

export async function check({ ids }: Options) {
  known(ids);
  await shellReady("check");
  return inPlace(ids);
}

export async function install({ ids }: Options) {
  known(ids);
  await shellReady();
  let changed = false;
  await mkdir(PLUGINS, { recursive: true });
  for (const id of ids) {
    if (await copied(id)) continue;
    // The folder is swapped in whole, so no file of an earlier version stays.
    const stage = mkdtempSync(`${PLUGINS}/.omarchy-bar-own-widgets.`);
    await cp(`${SRC}/${id}`, stage, { recursive: true });
    await rm(`${PLUGINS}/${id}`, { recursive: true, force: true });
    await rename(stage, `${PLUGINS}/${id}`);
    changed = true;
  }
  await $`omarchy-shell shell rescanPlugins`.quiet();
  for (const id of ids) {
    for (let tries = 1; !(await widgetEnabled(id)) && !(await succeeds($`omarchy plugin enable ${id}`)); tries++) {
      if (tries >= 20) throw new Error(`couldn't enable ${id} (is omarchy-shell running?)`);
      await Bun.sleep(500);
    }
  }
  if (changed) {
    // A loaded plugin keeps its old QML until the shell restarts. Quickshell
    // can crash when killed mid hot-reload, so the files settle first.
    await Bun.sleep(3000);
    if (!(await succeeds($`omarchy restart shell`))) tell("restart the Omarchy shell to load the new widgets (omarchy restart shell)");
    await shellReady().catch(() => {});
  }
  if (!(await inPlace(ids))) throw new Error("the widgets aren't installed and enabled after install");
}
