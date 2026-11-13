import { omarchyAur, program, via } from "loadout";

// The AUR's brave-bin (Brave's own build, repackaged), what Omarchy's
// `omarchy install browser brave` adds. The omarchy-brave script runs that
// installer for Omarchy's policy, flags and theme.
export const brave = program("brave", { description: "Brave browser", install: [via(omarchyAur, { pkg: "brave-bin" })] });
