#!/usr/bin/env bun
// Miyo's launcher entry and its login autostart (XDG autostart: uwsm runs it on
// Omarchy). The machine's arguments are environment for Miyo: on the T2,
// GGML_VK_VISIBLE_DEVICES=0 keeps its embedding server on the Intel iGPU, where
// it otherwise spreads over both GPUs and takes ~0.7 GB of the Radeon's 4 GB,
// which llama-server needs.
// usage: launcher.ts [check|install] [VAR=value…]
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { fail, main, read } from "loadout/script";

const HOME = process.env.HOME!;
const ENTRIES = [
  `${process.env.XDG_DATA_HOME || `${HOME}/.local/share`}/applications/miyo.desktop`,
  `${process.env.XDG_CONFIG_HOME || `${HOME}/.config`}/autostart/miyo.desktop`,
];

function entry(args: string[]) {
  // As the shell split them: a quoted value with spaces stays one.
  const env = args.filter(Boolean);
  const bad = env.find((e) => !/^[A-Z_][A-Z0-9_]*=\S*$/.test(e));
  if (bad) fail(`not VAR=value: ${bad}`);
  const exec = [...(env.length ? ["env", ...env] : []), `${HOME}/.local/bin/miyo-app`, "%U"].join(" ");
  return `[Desktop Entry]
Type=Application
Name=Miyo
Comment=Local semantic search for Obsidian Copilot
Exec=${exec}
Icon=system-search
Terminal=false
Categories=Office;Utility;
`;
}

async function ready(...args: string[]) {
  const want = entry(args);
  for (const path of ENTRIES) if ((await read(path)) !== want) return false;
  return true;
}

async function install(...args: string[]) {
  const want = entry(args);
  for (const path of ENTRIES) {
    mkdirSync(dirname(path), { recursive: true });
    await Bun.write(path, want);
  }
}

await main(ready, install);
