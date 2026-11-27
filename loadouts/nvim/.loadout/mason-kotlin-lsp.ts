// kotlin-lsp (kotlin.nvim's server), installed and kept current by Mason, with
// loadout watching it: its builds carry a licence that runs out a few weeks
// after their release, and the server then won't start, but Mason never
// updates what it has installed by itself. So Mason's newer version shows up
// in `loadout machine outdated`, and `loadout installer upgrade` has Mason install it (through
// outdated-kotlin-lsp.ts, the updates source). Neovim's kotlin.lua also asks
// Mason for it (ensure_installed). Mason is asked through mason.lua, under
// headless nvim (#nvim), with mason.nvim from the lazy plugins
// (script.nvim-plugins clones it).
//   check      Mason has kotlin-lsp
//   install    Mason installs the latest (the default; an update when installed)
import { masonHas, masonInstall } from "#nvim";

const PACKAGE = "kotlin-lsp";

export const check = () => masonHas(PACKAGE);

export const install = () => masonInstall(`${import.meta.dir}/mason.lua`, PACKAGE);
