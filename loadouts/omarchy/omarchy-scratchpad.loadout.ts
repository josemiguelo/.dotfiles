import { script } from "loadout";
import { kitty } from "../kitty/kitty.loadout.ts";
import { omarchyCommandOverrides } from "./omarchy-overrides.loadout.ts";

// Kitty windows in the scratchpad (Hyper+Escape) at the opacity the machine names;
// needs kitty.conf's dynamic_background_opacity, and the command overrides
// first on PATH (its text-size wrapper is one).
export const omarchyScratchpadOpacity = script("omarchy-scratchpad-opacity", {
  description: "scratchpad kitty windows less see-through",
  module: () => import("./.loadout/omarchy-scratchpad-opacity.ts"),
  rules: () => import("./.loadout/omarchy-scratchpad-opacity.rules.ts"),
  runAfter: [kitty, omarchyCommandOverrides],
});
