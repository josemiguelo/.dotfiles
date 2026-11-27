import { program, script, withOmarchyAur } from "loadout";

// The AUR's brave-bin (Brave's own build, repackaged), what Omarchy's
// `omarchy install browser brave` adds. The omarchy-brave script runs that
// installer for Omarchy's policy, flags and theme.
export const brave = program("brave", { description: "Brave browser", canBeInstalled: [withOmarchyAur({ packageName: "brave-bin" })] });

export const omarchyBrave = script("omarchy-brave", {
  description: "Brave, set up by Omarchy's browser installer",
  module: () => import("./.loadout/omarchy-brave.ts"),
  needsSudo: true,
  runAfter: [brave],
});
