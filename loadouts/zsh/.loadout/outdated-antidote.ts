// Custom `loadout machine outdated` oracle: is antidote itself behind its GitHub tip?
// Its bundles are a separate oracle (antidote-plugins). Silent when antidote
// isn't cloned on this machine.
//
// `update antidote` (loadout calls it per row) fast-forwards it.
import { clonesBehind, fastForward } from "loadout/script";
import { ANTIDOTE } from "#antidote";

const antidote = { name: "antidote", dir: ANTIDOTE };

export const listOutdated = () => clonesBehind([antidote]);
export const update = () => fastForward(antidote);
