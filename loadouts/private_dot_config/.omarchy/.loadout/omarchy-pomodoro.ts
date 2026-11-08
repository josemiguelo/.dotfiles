#!/usr/bin/env bun
// The Pomodoro timer plugin (pomodoro-omarchy, installed by omarchy-plugins;
// where it sits on the bar is omarchy-bar-widgets'): its settings from
// omarchy-pomodoro/settings.json (set with `omarchy bar set` into its
// shell.json entry; keys the file doesn't list are left as they are), and a
// Pomodoro submenu under Trigger in the Omarchy menu (Keystroke serves it):
// omarchy-pomodoro/menu.jsonc, kept as a block in the menu's extensions
// (menuBlockWrite in lib/omarchy.ts). They run the plugin's own
// bin/omarchy-pomodoro by its path, so nothing goes on the PATH.
// Modes: `check` / `install` (default).
import { main } from "#loadout";
import { menuBlockInPlace, menuBlockWrite, pluginUpdateHint, widgetConfigure, widgetConfigured, widgetEnabled } from "#omarchy";

const ID = "pomodoro-omarchy";
const NAME = "omarchy-pomodoro";
const SETTINGS = `${import.meta.dir}/omarchy-pomodoro/settings.json`;
const MENU_ENTRIES = `${import.meta.dir}/omarchy-pomodoro/menu.jsonc`;
const NOTE = "Pomodoro under Trigger (loadouts/private_dot_config/.omarchy/.loadout/omarchy-pomodoro.ts rewrites this block).";

const inPlace = async () =>
  (await widgetEnabled(ID)) && (await widgetConfigured(ID, SETTINGS)) && (await menuBlockInPlace(NAME, NOTE, MENU_ENTRIES));

async function install() {
  if (!(await widgetEnabled(ID))) throw new Error(`${ID} isn't installed and enabled: add it to omarchy-plugins`);
  if (!(await widgetConfigured(ID, SETTINGS))) await widgetConfigure(ID, SETTINGS);
  await menuBlockWrite(NAME, NOTE, MENU_ENTRIES);
  if (!(await inPlace())) {
    await pluginUpdateHint(ID);
    throw new Error("the Pomodoro plugin isn't configured and in the menu after install");
  }
}

await main(inPlace, install);
