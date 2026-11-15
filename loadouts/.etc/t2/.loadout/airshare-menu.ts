#!/usr/bin/env bun
// T2 AirShare in the Omarchy menu's Share submenu (Super+Ctrl+S), beside
// LocalSend's entries: a file, the clipboard or the last screenshot with
// AirShare (its send window picks the phone or Mac), and "Visible to Phones
// and Macs", checked while the receiver runs. The entries call the AirShare
// bar widget's helper (josemiguelo.airshare, omarchy-bar-own-widgets), and
// hide where T2 AirShare isn't installed. They're airshare-menu/menu.jsonc,
// kept as a block in the menu's extensions (menuBlockWrite in lib/omarchy.ts).
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { main } from "loadout/script";
import { MENU, PLUGINS, menuBlockInPlace, menuBlockWrite } from "#omarchy";

const NAME = "t2-airshare-menu";
const ENTRIES = `${import.meta.dir}/airshare-menu/menu.jsonc`;
const NOTE = "AirShare under Trigger > Share (loadouts/.etc/t2/.loadout/airshare-menu.ts rewrites this block).";
const HELPER = `${PLUGINS}/josemiguelo.airshare/airshare`;

const inPlace = async () => existsSync(HELPER) && (await menuBlockInPlace(NAME, NOTE, ENTRIES));

async function install() {
  if (!existsSync(HELPER)) throw new Error(`${HELPER} isn't there: the AirShare bar widget (omarchy-bar-own-widgets) installs it`);
  await menuBlockWrite(NAME, NOTE, ENTRIES);
  if (!(await inPlace())) throw new Error(`the AirShare entries aren't in ${MENU} after install`);
}

await main(inPlace, install);
