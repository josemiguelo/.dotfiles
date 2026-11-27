// Miyo's launcher entry and its login autostart (XDG autostart: uwsm runs it on
// Omarchy), both through a small wrapper, ~/.local/share/miyo/launch, that
// gives Miyo the machine's environment and puts its embedding server on the
// GPU named by `gpu`. On the T2, Intel: Miyo's llama.cpp
// otherwise spreads over both GPUs and takes ~0.7 GB of the Radeon's 4 GB,
// which llama-server needs. The wrapper looks the number up by name at every
// launch (Vulkan numbers the GPUs by which one drives the display), then execs
// Miyo: an autostart unit whose main process exits takes Miyo down with it.
// It also keeps Miyo from opening its dashboard at login (openDashboardOnStartup
// in ~/.config/Miyo/settings.json, once Miyo has written it): closing that
// window quits Miyo on Linux, and Copilot's search needs it running.
import { chmodSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { read } from "loadout/script";
import type { Options } from "./launcher.rules.ts";

const HOME = process.env.HOME!;
const DATA = process.env.XDG_DATA_HOME || `${HOME}/.local/share`;
const CONFIG = process.env.XDG_CONFIG_HOME || `${HOME}/.config`;
const WRAPPER = `${DATA}/miyo/launch`;
const ENTRIES = [`${DATA}/applications/miyo.desktop`, `${CONFIG}/autostart/miyo.desktop`];
const SETTINGS = `${CONFIG}/Miyo/settings.json`;

function wrapper({ gpu, env }: Options) {
  const lookup = gpu
    ? `
# The embedding server's GPU by name: its Vulkan number depends on the boot GPU.
i=$(env -u GGML_VK_VISIBLE_DEVICES llama-server --list-devices 2>/dev/null |
  sed -n 's/^ *Vulkan\\([0-9][0-9]*\\): .*${gpu}.*/\\1/p' | head -n 1)
[ -n "$i" ] && export GGML_VK_VISIBLE_DEVICES="$i"`
    : "";
  const exports = Object.entries(env ?? {}).map(([name, value]) => `\nexport ${name}='${value}'`).join("");
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

export async function check(options: Options) {
  if ((await read(WRAPPER)) !== wrapper(options)) return false;
  for (const path of ENTRIES) if ((await read(path)) !== entry) return false;
  const s = await settings();
  return s === null || s.openDashboardOnStartup === false;
}

export async function install(options: Options) {
  mkdirSync(dirname(WRAPPER), { recursive: true });
  await Bun.write(WRAPPER, wrapper(options));
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
