#!/usr/bin/env bun
// Brave, set up by Omarchy's own installer (`omarchy install browser brave`):
// the AUR's brave-bin, Omarchy's managed-policy directory, Omarchy's Chromium
// flags (~/.config/brave-flags.conf) and the Omarchy theme. It doesn't change
// the default browser (omarchy-default-browser-arch does that).
// Modes: `check` / `install` (default).
import { existsSync } from "node:fs";
import { $, main, ok } from "#loadout";

const CONFIG = process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`;

const ready = async () =>
  (await ok($`pacman -Q brave-bin`)) && existsSync(`${CONFIG}/brave-flags.conf`) && existsSync("/etc/brave/policies/managed");

async function install() {
  await $`omarchy install browser brave`;
  if (!(await ready())) throw new Error("Brave isn't fully set up");
}

await main(ready, install);
