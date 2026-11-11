#!/usr/bin/env bun
// Omarchy launches terminals through xdg-terminal-exec; omarchy-default-terminal
// writes the preference file (~/.config/xdg-terminals.list) it reads.
// Modes: `check` (kitty already first?) / `install` (default).
import { $, main } from "#loadout";

const WANT = "kitty";

/** The desktop id xdg-terminal-exec would launch, "" when it can't say. */
const current = async () =>
  (await $`xdg-terminal-exec --print-id`.quiet().nothrow()).stdout.toString().trim().split(":")[0];

await main(
  async () => (await current()) === `${WANT}.desktop`,
  async () => {
    await $`omarchy-default-terminal ${WANT}`;
  },
);
