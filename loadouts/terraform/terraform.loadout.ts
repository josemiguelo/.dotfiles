import { program } from "loadout";
import { withBrewTap } from "../homebrew/homebrew.loadout.ts";

// HashiCorp pulled terraform from homebrew-core over licensing (BSL); it
// ships only from their own tap now.
export const terraform = program("terraform", {
  description: "HashiCorp Terraform",
  canBeInstalled: [withBrewTap({ tap: "hashicorp/tap" })],
});
