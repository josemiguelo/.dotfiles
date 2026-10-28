package loadouts

import loadout.dsl.*

// HashiCorp pulled terraform from homebrew-core over licensing (BSL); it
// ships only from their own tap now.
val terraform = program(
    name = "terraform",
    description = "HashiCorp Terraform",
) {
    installVia(
        tap(tap = "hashicorp/tap"),
    )
}
