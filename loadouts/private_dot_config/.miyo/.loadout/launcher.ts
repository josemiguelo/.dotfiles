#!/usr/bin/env bun
// Miyo's launcher entry and its login autostart (XDG autostart: uwsm runs it on
// Omarchy), both through a small wrapper, ~/.local/share/miyo/launch, that
// gives Miyo the machine's environment and puts its embedding server on the
// GPU named by `--vulkan-gpu <name>`. On the T2, Intel: Miyo's llama.cpp
// otherwise spreads over both GPUs and takes ~0.7 GB of the Radeon's 4 GB,
// which llama-server needs. The wrapper looks the number up by name at every
// launch (Vulkan numbers the GPUs by which one drives the display), then execs
// Miyo: an autostart unit whose main process exits takes Miyo down with it.
// It also keeps Miyo from opening its dashboard at login (openDashboardOnStartup
// in ~/.config/Miyo/settings.json, once Miyo has written it): closing that
// window quits Miyo on Linux, and Copilot's search needs it running.
// usage: launcher.ts [check|install] [--vulkan-gpu <name>] [VAR=value…]
import { chmodSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { fail, main, read } from "loadout/script";

const HOME = process.env.HOME!;
const DATA = process.env.XDG_DATA_HOME || `${HOME}/.local/share`;
const CONFIG = process.env.XDG_CONFIG_HOME || `${HOME}/.config`;
const WRAPPER = `${DATA}/miyo/launch`;
const ENTRIES = [`${DATA}/applications/miyo.desktop`, `${CONFIG}/autostart/miyo.desktop`];
const SETTINGS = `${CONFIG}/Miyo/settings.json`;

function parse(args: string[]) {
  const words = [...args];
  const g = words.indexOf("--vulkan-gpu");
  const gpu = g >= 0 ? words.splice(g, 2)[1] : undefined;
  if (g >= 0 && !/^[A-Za-z0-9._-]+$/.test(gpu ?? "")) fail("--vulkan-gpu takes one word of the GPU's name");
  const bad = words.find((e) => !/^[A-Z_][A-Z0-9_]*=[^'\s]*$/.test(e));
  if (bad) fail(`not VAR=value: ${bad}`);
  return { gpu, env: words };
}

function wrapper({ gpu, env }: ReturnType<typeof parse>) {
  const lookup = gpu
    ? `
# The embedding server's GPU by name: its Vulkan number depends on the boot GPU.
i=$(env -u GGML_VK_VISIBLE_DEVICES llama-server --list-devices 2>/dev/null |
  sed -n 's/^ *Vulkan\\([0-9][0-9]*\\): .*${gpu}.*/\\1/p' | head -n 1)
[ -n "$i" ] && export GGML_VK_VISIBLE_DEVICES="$i"`
    : "";
  const exports = env.map((e) => `\nexport ${e.replace(/=(.*)$/, "='$1'")}`).join("");
  return `#!/bin/sh
# Managed by loadout (miyo-launcher): change the machine's args, not this file.${lookup}${exports}
exec "$HOME/.local/bin/miyo-app" "$@"
`;
}

const entry = `[Desktop Entry]
Type=Application
Name=Miyo
Comment=Local semantic search for Obsidian Copilot
Exec=${WRAPPER} %U
Icon=system-search
Terminal=false
Categories=Office;Utility;
`;

/** Miyo's settings, or null before its first launch writes them. */
async function settings() {
  const text = await read(SETTINGS);
  return text ? (JSON.parse(text) as Record<string, unknown>) : null;
}

async function ready(...args: string[]) {
  if ((await read(WRAPPER)) !== wrapper(parse(args))) return false;
  for (const path of ENTRIES) if ((await read(path)) !== entry) return false;
  const s = await settings();
  return s === null || s.openDashboardOnStartup === false;
}

async function install(...args: string[]) {
  mkdirSync(dirname(WRAPPER), { recursive: true });
  await Bun.write(WRAPPER, wrapper(parse(args)));
  chmodSync(WRAPPER, 0o755);
  for (const path of ENTRIES) {
    mkdirSync(dirname(path), { recursive: true });
    await Bun.write(path, entry);
  }
  const s = await settings();
  if (s && s.openDashboardOnStartup !== false) {
    await Bun.write(SETTINGS, `${JSON.stringify({ ...s, openDashboardOnStartup: false }, null, 2)}\n`);
  }
}

await main(ready, install);
