#!/usr/bin/env bun
// The T2 Mac runs Omarchy's stable channel (docs/t2-macbook.md): its ISO is
// built with omarchy-iso's --local-source --stable from t2-kait2en-stable, the
// fork's T2 commits on the commit stable's package is built from. An ISO built
// without --stable installs edge's -dev packages and the edge repo instead,
// and nothing on the machine says so: the 2026-11-11 reinstall came from a
// stick written before --stable existed and ran edge until this caught it.
//
// check: the stable packages (omarchy, omarchy-settings, not their -dev
// builds), with both the mirror and the package repo on stable
// (omarchy-version-channel prints one word only when they agree), and no
// linked source checkout (OMARCHY_PATH) overriding them.
// install: omarchy-channel-set stable, which refreshes pacman.conf from the
// stable template (t2-arch-packages-repo's pre-refresh-pacman hook, which runs
// first, puts the [t2-arch-packages] repo back), swaps the packages and runs
// omarchy-update.
// Modes: `check` / `install` (default).
import { $, main, ok, out } from "#loadout";

const CHANNEL = "stable";

async function current() {
  const path = process.env.OMARCHY_PATH;
  if (path && path !== "/usr/share/omarchy") return "dev";
  if (await ok($`pacman -Q omarchy-dev`)) return "edge";
  if (await ok($`pacman -Q omarchy-settings-dev`)) return "edge";
  if (!(await ok($`pacman -Q omarchy omarchy-settings`))) return "unknown";
  return await out($`omarchy-version-channel`.nothrow());
}

const ready = async () => (await current()) === CHANNEL;

async function install() {
  const was = await current();
  console.log(`t2-omarchy-channel: on ${was}, switching to ${CHANNEL}`);
  await $`omarchy-channel-set ${CHANNEL}`;
  const now = await current();
  if (now !== CHANNEL) throw new Error(`still on ${now} after omarchy-channel-set ${CHANNEL}`);
}

await main(ready, install);
