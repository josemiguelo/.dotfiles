#!/usr/bin/env bun
// Symlink JetBrains Toolbox IDE launcher scripts into ~/.local/bin.
// check mode: every Toolbox script must be symlinked (nothing to do when the
// Toolbox scripts dir doesn't exist yet).
import { existsSync, lstatSync, mkdirSync, readdirSync, statSync } from "node:fs";
import { $, main } from "#loadout";

const HOME = process.env.HOME!;
const SCRIPTS_DIR = `${HOME}/.local/share/JetBrains/Toolbox/scripts`;
const BIN_DIR = `${HOME}/.local/bin`;

/** The Toolbox's launcher scripts (regular files, as a symlink's target counts). */
const scripts = () =>
  existsSync(SCRIPTS_DIR) ? readdirSync(SCRIPTS_DIR).filter((n) => statSync(`${SCRIPTS_DIR}/${n}`).isFile()) : [];

const linked = (name: string) => {
  try {
    return lstatSync(`${BIN_DIR}/${name}`).isSymbolicLink();
  } catch {
    return false;
  }
};

const ready = () => scripts().every(linked);

async function install() {
  if (!existsSync(SCRIPTS_DIR)) {
    console.log("JetBrains Toolbox scripts directory not found, skipping");
    return;
  }
  mkdirSync(BIN_DIR, { recursive: true });
  for (const name of scripts()) {
    await $`ln -sf ${`${SCRIPTS_DIR}/${name}`} ${`${BIN_DIR}/${name}`}`;
    console.log(`symlinked ${name} -> ${SCRIPTS_DIR}/${name}`);
  }
}

await main(ready, install);
