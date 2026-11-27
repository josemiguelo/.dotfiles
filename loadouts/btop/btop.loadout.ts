// btop: the activity monitor, and what its GPU boxes need to read an AMD card.
import { program, withBrew, withOmarchy } from "loadout";

export const btop = program("btop", { canBeInstalled: [withBrew, withOmarchy] });

// ROCm SMI: btop loads it at runtime to read AMD GPUs; without it the amdgpu
// card has no box.
export const rocmSmiLib = program("rocm-smi-lib", { description: "ROCm SMI library (btop's AMD GPU stats)", canBeInstalled: [withOmarchy] });
