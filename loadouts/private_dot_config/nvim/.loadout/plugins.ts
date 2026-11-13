#!/usr/bin/env bun
// lazy.nvim plugins, exactly as ~/.config/nvim/lazy-lock.json pins them (the
// lockfile comes from the chezmoi dotfiles), asked of Lazy under headless nvim
// through plugins.lua (#nvim):
//   check      does the disk match the lock? EVERY plugin the spec enables is
//              cloned AND sits on its locked commit — a lock moved on another
//              machine lands here as a file change only; the clone is what
//              runs.
//   install    make it so: Lazy's own `restore`.
// outdated-plugins.ts is the other half: what's newer upstream, and moving one.
// Modes: `check` / `install` (default).
import { main } from "loadout/script";
import { lazyCheck, lazyInstall } from "#nvim";

const ready = () => lazyCheck(`${import.meta.dir}/plugins.lua`);

await main(ready, lazyInstall);
