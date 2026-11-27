// The nvim-plugins updates source: with no arguments, the plugins Lazy calls
// outdated (`<plugin> <current> <candidate>` lines, honouring each plugin's
// version/tag/commit/branch/pin); `update <plugin>` moves one, through Lazy, so
// Lazy stays the only writer of the pins. Both ask plugins.lua (#nvim).
import { lazyOutdated, lazyUpdate } from "#nvim";

const LUA = `${import.meta.dir}/plugins.lua`;

export const listOutdated = () => lazyOutdated(LUA);
export const update = (plugin: string) => lazyUpdate(LUA, plugin);
