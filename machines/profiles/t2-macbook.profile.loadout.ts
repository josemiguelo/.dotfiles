import { args, omarchy, profile, via } from "loadout";
import type { Data } from "../data.ts";
import { t2ArchPackagesRepo, t2HybridBoot, t2BcmFirmware, t2ChargeLimit, t2OmarchyChannel, t2PostUpdateCheck, t2TouchIdAuth, t2KeySwaps } from "../../loadouts/.etc/t2/.t2.loadout.ts";
import { omarchySshd } from "../../loadouts/.ssh/.omarchy-sshd.loadout.ts";
import { sshKey } from "../../loadouts/.ssh/.ssh.loadout.ts";
import { omarchyActivityMonitorSize } from "../../loadouts/private_dot_config/.hypr/.hyprland.loadout.ts";
import { archVirtualization, setupLibvirt, ufwLibvirt } from "../../loadouts/private_dot_config/.libvirt/.libvirt.loadout.ts";
import { ggmlVulkan, llamaCpp, llamaServer, llmModel } from "../../loadouts/private_dot_config/.llama-cpp/.llama-cpp.loadout.ts";
import { fuse2, miyo, miyoLauncher } from "../../loadouts/private_dot_config/.miyo/.miyo.loadout.ts";
import { obsidianCopilot, obsidianVault } from "../../loadouts/private_dot_config/.obsidian/.obsidian.loadout.ts";
import { omarchySudolessDocker } from "../../loadouts/private_dot_config/.omarchy/.omarchy-apps.loadout.ts";
import { omarchyScratchpadOpacity } from "../../loadouts/private_dot_config/.omarchy/.omarchy-scratchpad.loadout.ts";
import { solaar, solaarNoAutostart } from "../../loadouts/private_dot_config/.solaar.loadout.ts";
import { superwhisperGpu } from "../../loadouts/private_dot_config/.superwhisper/.superwhisper.loadout.ts";
import { rocmSmiLib } from "../../loadouts/private_dot_config/btop/.btop.loadout.ts";
import { omarchyProfile } from "./omarchy.profile.loadout.ts";

// Every MacBookPro16,1 (T2) running Omarchy: the T2 hardware fixes and what
// these machines run on top of Omarchy. Each install is its own machine
// (named by its hostname, so each keeps its own state file).
export const t2Macbook = profile<Data>("t2-macbook", {
  extends: [omarchyProfile],
  data: { miyo: true },
  install: [
    via(omarchy, [
      // the [t2-arch-packages] repo; the T2 packages come with the t2-mac and
      // t2-mac-hybrid meta-packages (the Omarchy fork's installer), not here
      t2ArchPackagesRepo,
      archVirtualization,
      solaar,
      rocmSmiLib,  // btop's stats for the Radeon Pro 5300M/5500M
      // the local LLM for Obsidian Copilot (docs/local-llm.md)
      llamaCpp,
      ggmlVulkan,
      fuse2,  // Miyo's AppImage
    ]),
    miyo,
  ],
  run: [
    sshKey("id_ed25519"),
    // The GitHub keys (by title) that get a shell here.
    args(omarchySshd, "t2-macbook-omarchy", "t2-macbook-omarchy-2", "omarchy-vm", "work-mac"),
    t2OmarchyChannel,
    t2KeySwaps,
    t2HybridBoot,
    t2BcmFirmware,
    // The SMC stops charging 5 points below the limit: 90 holds the battery at 85 %.
    args(t2ChargeLimit, "90"),
    t2TouchIdAuth,
    t2PostUpdateCheck,
    setupLibvirt,
    ufwLibvirt,
    omarchySudolessDocker,
    args(omarchyActivityMonitorSize, "90%", "90%"),
    args(omarchyScratchpadOpacity, "0.99"),
    solaarNoAutostart,
    // The local LLM, sized for 64 GB of RAM and the Radeon's 4 GB (docs/local-llm.md):
    // a Mixture-of-Experts model, ~3B of its 35B parameters at work per token.
    args(
      llmModel,
      "unsloth/Qwen3.6-35B-A3B-GGUF",
      "a483e9e6cbd595906af30beda3187c2663a1118c",  // the repo's commit, so a re-upload can't change it
      "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf",
      "ac0e2c1189e055faa36eff361580e79c5bd6f8e76bffb4ce547f167d53e31a61",
    ),
    args(
      llamaServer,
      "--vulkan-gpu Radeon",             // by name: Vulkan's numbers follow the boot GPU
      "GGML_OP_OFFLOAD_MIN_BATCH=1024",  // prompts under 1024 tokens are faster on the CPU
      "--model Qwen3.6-35B-A3B-UD-Q4_K_M.gguf",
      "--alias qwen3.6-35b-a3b",
      "--host 127.0.0.1 --port 8080",
      "-c 32768",                        // 16K overflowed in Agent Chat; 64K fills the VRAM
      "-t 8 -np 1",                      // the 8 cores, one user
      "-ngl 99 --n-cpu-moe 41",          // attention on the GPU, every layer's experts in RAM
      "-ub 2048 -b 2048",                // big batches: ~175 tok/s prompt reading
      "-fa on --jinja",
      // Thinking takes minutes here. Args go through a shell: the JSON is single-quoted.
      `--chat-template-kwargs '{"enable_thinking":false}'`,
    ),
    // Waits on a new machine for the Obsidian login and Sync, like 1Password does.
    args(obsidianVault, "~/Obsidian/vaults/jm"),
    args(
      obsidianCopilot,
      "~/Obsidian/vaults/jm",
      "http://127.0.0.1:8080/v1",
      "qwen3.6-35b-a3b",
      "32768",  // llama-server's -c, passed on to OpenCode so it doesn't assume 200K
      "8",      // Miyo results per search: each is text the 32K context has to hold
    ),
    args(miyoLauncher, "--vulkan-gpu Intel"),  // its embeddings on the iGPU, off the Radeon
    // Dictation on the iGPU too (Intel UHD 630): its models took ~2.9 GB of the
    // Radeon, and llama-server crashed beside them.
    args(superwhisperGpu, "8086:3e9b"),
  ],
});
