// lazy.nvim plugins, exactly as ~/.config/nvim/lazy-lock.json pins them (the
// lockfile comes from the chezmoi dotfiles), asked of Lazy under headless nvim
// through plugins.lua (#nvim):
//   check      does the disk match the lock? EVERY plugin the spec enables is
//              cloned AND sits on its locked commit — a lock moved on another
//              machine lands here as a file change only; the clone is what
//              runs.
//   install    make it so: Lazy's own `restore`.
// outdated-plugins.ts is the other half: what's newer upstream, and moving one.
import { lazyCheck, lazyInstall } from "#nvim";

export const check = () => lazyCheck(`${import.meta.dir}/plugins.lua`);

export const install = lazyInstall;
