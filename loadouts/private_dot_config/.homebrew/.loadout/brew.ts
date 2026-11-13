#!/usr/bin/env bun
// brew by absolute path, for what can't import #loadout's brew(): the
// manifest's `version: runScript(".loadout/brew.ts --version")`, and
// anything else that needs brew by a custom command, as
// `bun "$LOADOUT_REPO/loadouts/private_dot_config/.homebrew/.loadout/brew.ts" <brew args...>`.
// It is #loadout's brew(): a PATH brew first so a custom prefix still works,
// then this OS's prefix (brew-prefix.sh), unattended (HOMEBREW_NO_ASK), so
// converging never depends on the shell having run `brew shellenv` (on a fresh
// machine the dotfiles that do that come AFTER the programs). brew's exit code
// is this script's; without brew it says so and exits 1.
// usage: brew.ts <brew args...>
import { run } from "loadout/script";
import { brew } from "#brew";

async function passthrough(...args: string[]) {
  process.exit((await brew(...args).nothrow()).exitCode);
}

await run(passthrough);
