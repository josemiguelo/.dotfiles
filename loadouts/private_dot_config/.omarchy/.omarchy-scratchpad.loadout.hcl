# Kitty windows in the scratchpad (SUPER+S) at the opacity the machine names;
# needs kitty.conf's dynamic_background_opacity.
script "omarchy-scratchpad-opacity" {
  description = "scratchpad kitty windows less see-through"
  managed_by  = ".loadout/omarchy-scratchpad-opacity.sh"
  run_after   = [program.kitty]
}
