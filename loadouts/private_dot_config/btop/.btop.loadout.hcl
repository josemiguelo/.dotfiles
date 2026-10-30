# btop: the activity monitor, and what its GPU boxes need to read an AMD card.

program "btop" {
  install_via = [brew, omarchy]
}

# ROCm SMI: btop loads it at runtime to read AMD GPUs; without it the amdgpu
# card has no box.
program "rocm-smi-lib" {
  description = "ROCm SMI library (btop's AMD GPU stats)"
  install_via = [omarchy]
}
