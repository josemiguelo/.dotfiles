#!/usr/bin/env bun
// Custom `loadout outdated` oracle: is antidote itself behind its GitHub tip?
// Its bundles are a separate oracle (antidote-plugins). Silent when antidote
// isn't cloned on this machine.
//
// `update antidote` (loadout calls it per row) fast-forwards it.
// usage: outdated-antidote.ts [update antidote]
import { clonesBehind, fastForward, formatRow, run } from "loadout/script";
import { ANTIDOTE } from "#antidote";

const antidote = { name: "antidote", dir: ANTIDOTE };

async function outdated(mode?: string, want?: string) {
  if (mode === "update") {
    if (want !== antidote.name) throw new Error(`no clone named '${want}' here`);
    await fastForward(antidote);
    return;
  }
  if (mode !== undefined) throw new Error("usage: outdated-antidote.ts [update antidote]");
  for (const row of await clonesBehind([antidote])) console.log(formatRow(row));
}

await run(outdated);
