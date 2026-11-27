import { profile, withOmarchy } from "loadout";
import type { Data } from "../data.ts";
import { t2ArchPackagesRepo, t2HybridBoot, t2BcmFirmware, t2ChargeLimit, t2OmarchyChannel, t2PostUpdateCheck, t2TouchIdAuth, t2KeySwaps } from "../../loadouts/t2/t2.loadout.ts";
import { omarchySshd } from "../../loadouts/ssh/omarchy-sshd.loadout.ts";
import { sshKey } from "../../loadouts/ssh/ssh.loadout.ts";
import { omarchyActivityMonitorSize } from "../../loadouts/hypr/hyprland.loadout.ts";
import { archVirtualization, setupLibvirt, ufwLibvirt } from "../../loadouts/libvirt/libvirt.loadout.ts";
import { ggmlVulkan, llamaCpp, llamaServer, llmModel } from "../../loadouts/llama-cpp/llama-cpp.loadout.ts";
import { fuse2, miyo, miyoLauncher } from "../../loadouts/miyo/miyo.loadout.ts";
import { obsidianCopilot, obsidianOpencode, obsidianRgignore, obsidianVault } from "../../loadouts/obsidian/obsidian.loadout.ts";
import { omarchySudolessDocker } from "../../loadouts/docker/docker.loadout.ts";
import { omarchyScratchpadOpacity } from "../../loadouts/omarchy/omarchy-scratchpad.loadout.ts";
import { omarchyBarFn } from "../../loadouts/omarchy/omarchy-shell.loadout.ts";
import { solaar, solaarNoAutostart } from "../../loadouts/solaar/solaar.loadout.ts";
import { superwhisperGpu } from "../../loadouts/superwhisper/superwhisper.loadout.ts";
import { rocmSmiLib } from "../../loadouts/btop/btop.loadout.ts";
import { omarchyProfile } from "./omarchy.profile.loadout.ts";

// The local LLM (docs/local-llm.md): what its scripts share.
const model = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
const alias = "qwen3.6-35b-a3b";
const port = 8080;
const context = 32768;
const vault = "~/Obsidian/vaults/jm";

// Every MacBookPro16,1 (T2) running Omarchy: the T2 hardware fixes and what
// these machines run on top of Omarchy. Each install is its own machine
// (named by its hostname, so each keeps its own state file).
export const t2Macbook = profile<Data>("t2-macbook", {
  extends: [omarchyProfile],
  data: { miyo: true },
  install: [
    withOmarchy(
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
    ),
    miyo,
  ],
  run: [
    sshKey("id_ed25519"),
    // The GitHub keys (by title) that get a shell here.
    omarchySshd({ keys: ["t2-macbook-omarchy", "t2-macbook-omarchy-2", "omarchy-vm", "work-mac"] }),
    t2OmarchyChannel,
    t2KeySwaps,
    t2HybridBoot,
    t2BcmFirmware,
    // The SMC stops charging 5 points below the limit: 90 holds the battery at 85 %.
    t2ChargeLimit({ limit: 90 }),
    t2TouchIdAuth,
    t2PostUpdateCheck,
    setupLibvirt,
    ufwLibvirt,
    omarchySudolessDocker,
    omarchyActivityMonitorSize({ width: "90%", height: "90%" }),
    omarchyScratchpadOpacity({ opacity: 0.99 }),
    solaarNoAutostart,
    // The local LLM, sized for 64 GB of RAM and the Radeon's 4 GB (docs/local-llm.md):
    // a Mixture-of-Experts model, ~3B of its 35B parameters at work per token.
    llmModel({
      repo: "unsloth/Qwen3.6-35B-A3B-GGUF",
      commit: "a483e9e6cbd595906af30beda3187c2663a1118c",  // so a re-upload can't change it
      file: model,
      sha256: "ac0e2c1189e055faa36eff361580e79c5bd6f8e76bffb4ce547f167d53e31a61",
    }),
    llamaServer({
      gpu: "Radeon",  // by name: Vulkan's numbers follow the boot GPU
      model,
      alias,
      host: "127.0.0.1",
      port,
      env: { GGML_OP_OFFLOAD_MIN_BATCH: 1024 },  // prompts under 1024 tokens are faster on the CPU
      flags: {
        "-c": context,       // 16K overflowed in Agent Chat; 64K fills the VRAM
        "-t": 8,             // the 8 cores
        "-np": 1,            // one user
        "-ngl": 99,          // attention on the GPU...
        "--n-cpu-moe": 41,   // ...every layer's experts in RAM
        "-ub": 2048,         // big batches: ~175 tok/s prompt reading
        "-b": 2048,
        "-fa": "on",
        "--jinja": true,
        "--chat-template-kwargs": JSON.stringify({ enable_thinking: false }),  // thinking takes minutes here
      },
    }),
    // Waits on a new machine for the Obsidian login and Sync, like 1Password does.
    obsidianVault({ vault }),
    obsidianCopilot({
      vault,
      baseUrl: `http://127.0.0.1:${port}/v1`,
      model: alias,
      context,         // passed on to OpenCode so it doesn't assume 200K
      miyoResults: 8,  // each is text the context has to hold
    }),
    // Agent Chat compacts at ~27.7K of the 32K (OpenCode's own sizes: at 16.8K).
    obsidianOpencode({ vault, buffer: 5000, keep: 6000, skills: ["obsidian-markdown", "obsidian-bases", "json-canvas"] }),
    obsidianRgignore({ vault, patterns: ["/.obsidian/", "/.copilot/", "/copilot/copilot-conversations/"] }),
    miyoLauncher({ gpu: "Intel" }),  // its embeddings on the iGPU, off the Radeon
    // The shared bar, plus the T2 panel (t2.panel: a tab per T2 feature
    // installed), which t2-omarchy-plugins brings (t2-omarchy-setup links and
    // places it; Omarchy's first login runs it), so only where it sits is here;
    // and a switch in the tray to start and stop llama-server
    // (llama-toggle: systemd user units only; its models setting names just
    // llama-server.service, or it would list llama-warmup too).
    omarchyBarFn({
      plugins: ["https://github.com/thesilentbear/llama-toggle.git"],
      widgets: [
        { id: "t2.panel", section: "right", before: "omarchy.bluetooth" },
        { id: "dev.thesilentbear.llama-toggle", section: "tray", at: 0 },
      ],
    }),
    // Dictation on the iGPU too (Intel UHD 630): its models took ~2.9 GB of the
    // Radeon, and llama-server crashed beside them.
    superwhisperGpu({ pciId: "8086:3e9b" }),
  ],
});
