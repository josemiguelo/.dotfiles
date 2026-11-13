#!/usr/bin/env bun
// Where installed bar widgets (omarchy-plugins, omarchy-bar-own-widgets) sit,
// from the machine's multi-line opt-in, one widget per line:
// "<id> <section> <before|after> <neighbour-id>"
// ("io.github.sumdahl.media right after omarchy.tray"; the sections are
// Omarchy's: left, centerBegin, center, centerEnd, tray, right), or
// "<id> <section> at <index>" for a widget with no neighbour to sit by (the
// clock, alone in center, placed to get its settings). Placement is
// Omarchy's own bar layout (~/.config/omarchy/shell.json), changed with
// `omarchy bar move`, or `omarchy bar put` for a widget off the bar (enabled
// by its plugins[] entry alone, like Keystroke's menu). A widget with
// omarchy-bar/settings/<id>.json gets those settings set with `omarchy bar
// set` into its entry (keys the file doesn't list are left as they are;
// widgetConfigure in lib/omarchy.ts). The check: each widget enabled, right
// before/after its neighbour (or at its index) in that section, and every
// listed setting at its value. Widgets are placed in the opt-in's order, so
// a neighbour is one already in the section (stock, or placed by an earlier
// line).
// usage: omarchy-bar-widgets.ts [check] "<id> <section> <before|after|at> <neighbour|index>"...
import { $, fail, main, ok } from "loadout/script";
import {
  SHELL_JSON,
  pluginUpdateHint,
  readJson,
  shellReady,
  widgetConfigure,
  widgetConfigured,
  widgetEnabled,
  widgetOnBar,
} from "#omarchy";

const USAGE = 'usage: omarchy-bar-widgets.ts [check] "<id> <section> <before|after|at> <neighbour|index>"...';

type Place = { id: string; section: string; rel: "before" | "after" | "at"; neighbour: string };

/** The arguments as one widget per line: loadout splits a multi-line opt-in on whitespace, so the words are regrouped in fours. */
function places(args: string[]): Place[] {
  if (args.length === 0) fail(USAGE);
  const words = args.join(" ").split(/\s+/).filter(Boolean);
  if (words.length % 4) fail("each widget needs four words: <id> <section> <before|after|at> <neighbour|index>");
  const out: Place[] = [];
  for (let i = 0; i < words.length; i += 4) {
    const [id, section, rel, neighbour] = words.slice(i, i + 4);
    if (rel === "at" && !/^[0-9]+$/.test(neighbour)) fail(`${id}: at <index>, not '${neighbour}'`);
    if (rel !== "before" && rel !== "after" && rel !== "at") fail(`${id}: <before|after|at>, not '${rel}'`);
    out.push({ id, section, rel, neighbour });
  }
  return out;
}

const settingsOf = (id: string) => `${import.meta.dir}/omarchy-bar/settings/${id}.json`;

async function placed({ id, section, rel, neighbour }: Place) {
  const shell = await readJson(SHELL_JSON);
  if (!shell) return false;
  const ids: string[] = (shell.bar?.layout?.[section] ?? []).map((e: any) => e?.id);
  const i = ids.indexOf(id);
  if (rel === "at") return i === Number(neighbour);
  const j = ids.indexOf(neighbour);
  return i >= 0 && j >= 0 && (rel === "before" ? i + 1 === j : i === j + 1);
}

const inPlace = async (p: Place) => (await widgetEnabled(p.id)) && (await placed(p)) && (await widgetConfigured(p.id, settingsOf(p.id)));

async function check(...args: string[]) {
  const all = places(args);
  await shellReady("check");
  let done = true;
  for (const p of all) if (!(await inPlace(p))) done = false;
  return done;
}

async function install(...args: string[]) {
  const all = places(args);
  await shellReady();
  let failed = false;
  for (const p of all) {
    const flag = p.rel === "at" ? "--index" : `--${p.rel}`;
    if (!(await widgetOnBar(p.id))) await ok($`omarchy bar put ${p.id} --section ${p.section} ${flag} ${p.neighbour}`);
    if (!(await widgetEnabled(p.id))) {
      console.error(`${p.id} isn't installed and enabled`);
      failed = true;
      continue;
    }
    // A neighbour not in the section yet fails the move; the check below says so.
    if (!(await placed(p))) await ok($`omarchy bar move ${p.id} --section ${p.section} ${flag} ${p.neighbour}`);
    if (!(await widgetConfigured(p.id, settingsOf(p.id)))) await widgetConfigure(p.id, settingsOf(p.id));
    if (!(await inPlace(p))) {
      console.error(`${p.id} isn't at ${p.section}, ${p.rel} ${p.neighbour}, with its settings after install`);
      await pluginUpdateHint(p.id);
      failed = true;
    }
  }
  if (failed) process.exit(1);
}

await main(check, install);
