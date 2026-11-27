// The mason-kotlin-lsp updates source: with no arguments, `kotlin-lsp
// <installed> <latest>` when Mason has a newer build; `update <item>` has
// Mason install it. Both ask mason.lua (#nvim).
import { masonInstall, masonOutdated } from "#nvim";

const PACKAGE = "kotlin-lsp";
const LUA = `${import.meta.dir}/mason.lua`;

export const listOutdated = () => masonOutdated(LUA, PACKAGE);
export const update = () => masonInstall(LUA, PACKAGE);
