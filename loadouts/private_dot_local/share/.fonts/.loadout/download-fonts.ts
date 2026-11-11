#!/usr/bin/env bun
// FiraCode nerd fonts into the user font dir. macOS registers fonts placed
// in ~/Library/Fonts automatically; Linux needs fc-cache after copying.
// Modes: `check` (fonts present?) / `install` (default).
import { copyFileSync, existsSync, mkdirSync, readdirSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { $, main } from "#loadout";

const URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/FiraCode.zip";
const darwin = process.platform === "darwin";
const target = darwin ? `${process.env.HOME}/Library/Fonts` : `${process.env.HOME}/.local/share/fonts`;

const fira = (dir: string) => (existsSync(dir) ? readdirSync(dir).filter((n) => n.startsWith("Fira Code")) : []);

await main(
  () => fira(target).length > 0,
  async () => {
    const tmp = await mkdtemp(`${tmpdir()}/fonts-`);
    try {
      await $`curl -fsSL -o ${`${tmp}/FiraCode.zip`} ${URL}`;
      await $`unzip ${`${tmp}/FiraCode.zip`} -d ${`${tmp}/FiraCode`}`;
      mkdirSync(target, { recursive: true });
      for (const font of fira(`${tmp}/FiraCode`)) copyFileSync(`${tmp}/FiraCode/${font}`, `${target}/${font}`);
      if (!darwin) await $`fc-cache -fv`;
    } finally {
      await rm(tmp, { recursive: true, force: true });
    }
  },
);
