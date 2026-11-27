// Where installed bar widgets (omarchy-plugins, omarchy-bar-own-widgets) sit,
// in the order the machine lists them: right before or after a neighbour in a
// section, or at an index for a widget with no neighbour to sit by (the
// clock, alone in center, placed to get its settings). Placement is
// Omarchy's own bar layout (~/.config/omarchy/shell.json), changed with
// `omarchy bar move`, or `omarchy bar put` for a widget off the bar (enabled
// by its plugins[] entry alone, like Keystroke's menu). A widget with
// omarchy-bar/settings/<id>.json gets those settings set with `omarchy bar
// set` into its entry (keys the file doesn't list are left as they are;
// widgetConfigure in lib/omarchy.ts). The check: each widget enabled, right
// before/after its neighbour (or at its index) in that section, and every
// listed setting at its value. Widgets are placed in order, so a neighbour is
// one already in the section (stock, or placed before it).
import { $, succeeds } from "loadout/script";
import {
  SHELL_JSON,
  pluginUpdateHint,
  readJson,
  settled,
  shellReady,
  widgetConfigure,
  widgetConfigured,
  widgetEnabled,
  widgetOnBar,
} from "#omarchy";
import type { Options, Widget } from "./omarchy-bar-widgets.rules.ts";

/** Where the widget goes, as `omarchy bar` takes it. */
function spot(w: Widget): [flag: string, value: string] {
  if (w.before !== undefined) return ["--before", w.before];
  if (w.after !== undefined) return ["--after", w.after];
  return ["--index", String(w.at)];
}

const settingsOf = (id: string) => `${import.meta.dir}/omarchy-bar/settings/${id}.json`;

async function placed(w: Widget) {
  const shell = await readJson(SHELL_JSON);
  if (!shell) return false;
  const ids: string[] = (shell.bar?.layout?.[w.section] ?? []).map((e: any) => e?.id);
  const i = ids.indexOf(w.id);
  if (w.at !== undefined) return i === w.at;
  const j = ids.indexOf(w.before ?? w.after);
  return i >= 0 && j >= 0 && (w.before !== undefined ? i + 1 === j : i === j + 1);
}

const inPlace = async (p: Widget) => (await widgetEnabled(p.id)) && (await placed(p)) && (await widgetConfigured(p.id, settingsOf(p.id)));

export async function check({ widgets }: Options) {
  await shellReady("check");
  let done = true;
  for (const p of widgets) if (!(await inPlace(p))) done = false;
  return done;
}

export async function install({ widgets }: Options) {
  await shellReady();
  let failed = false;
  for (const p of widgets) {
    const [flag, value] = spot(p);
    if (!(await widgetOnBar(p.id)) && (await succeeds($`omarchy bar put ${p.id} --section ${p.section} ${flag} ${value}`))) {
      await settled(() => widgetOnBar(p.id));
    }
    if (!(await widgetEnabled(p.id))) {
      console.warn(`${p.id} isn't installed and enabled`);
      failed = true;
      continue;
    }
    // A neighbour not in the section yet fails the move; the check below says so.
    // Each waits for shell.json to show it: the next widget may sit by this one.
    if (!(await placed(p)) && (await succeeds($`omarchy bar move ${p.id} --section ${p.section} ${flag} ${value}`))) {
      await settled(() => placed(p));
    }
    if (!(await widgetConfigured(p.id, settingsOf(p.id)))) await widgetConfigure(p.id, settingsOf(p.id));
    if (!(await settled(() => inPlace(p)))) {
      console.warn(`${p.id} isn't at ${p.section}, ${flag.slice(2)} ${value}, with its settings after install`);
      await pluginUpdateHint(p.id);
      failed = true;
    }
  }
  if (failed) process.exit(1);
}
