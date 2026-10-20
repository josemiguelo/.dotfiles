package repo

import loadout.dsl.*

/** Kitty windows in the scratchpad (SUPER+S) at the opacity the machine names; needs kitty.conf's dynamic_background_opacity. */
val omarchyScratchpadOpacity = script(
    name = "omarchy-scratchpad-opacity",
    description = "scratchpad kitty windows less see-through",
) {
    managedBy("omarchy-scratchpad-opacity.sh")
    runAfter(kitty)
}
