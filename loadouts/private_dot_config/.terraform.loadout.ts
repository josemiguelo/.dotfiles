import { program, via } from "loadout";
import { brewTap } from "./.homebrew/.homebrew.loadout.ts";

// HashiCorp pulled terraform from homebrew-core over licensing (BSL); it
// ships only from their own tap now.
export const terraform = program("terraform", {
  description: "HashiCorp Terraform",
  install: [via(brewTap, { params: { tap: "hashicorp/tap" } })],
});
