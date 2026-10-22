// btop: the activity monitor, and what its GPU boxes need to read an AMD card.
package repo

import loadout.dsl.*

val btop = program(name = "btop") {
    installVia(
        brew,
        omarchy,
    )
}

/** ROCm SMI: btop loads it at runtime to read AMD GPUs; without it the amdgpu card has no box. */
val rocmSmiLib = program(
    name = "rocm-smi-lib",
    description = "ROCm SMI library (btop's AMD GPU stats)",
) {
    installVia(
        omarchy,
    )
}
