import { script } from "loadout";
import { kitty } from "../kitty/.kitty.loadout.ts";

// Kitty windows in the scratchpad (Hyper+Escape) at the opacity the machine names;
// needs kitty.conf's dynamic_background_opacity.
export const omarchyScratchpadOpacity = script("omarchy-scratchpad-opacity", {
  description: "scratchpad kitty windows less see-through",
  managedBy: ".loadout/omarchy-scratchpad-opacity.ts",
  runAfter: [kitty],
});
