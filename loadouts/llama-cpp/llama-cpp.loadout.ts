// llama.cpp: the local LLM that Obsidian Copilot talks to (docs/local-llm.md).
// The model and the server's tuning are the hardware's, so the profile of the
// machines with that hardware names them.
import { program, script, withOmarchy } from "loadout";

// llama.cpp's GPU backend for the T2's Radeon (RDNA1: no ROCm support).
export const ggmlVulkan = program("ggml-vulkan", {
  description: "ggml's Vulkan backend: llama.cpp on the GPU",
  canBeInstalled: [withOmarchy],
});

export const llamaCpp = program("llama-cpp", {
  description: "llama.cpp: local LLM inference and its OpenAI-compatible server",
  dependsOn: [ggmlVulkan],
  canBeInstalled: [withOmarchy],
});

// One GGUF from Hugging Face at a pinned commit, checked against its SHA-256.
export const llmModel = script("llm-model", {
  description: "the local LLM's GGUF model, from Hugging Face",
  module: () => import("./.loadout/model.ts"),
  rules: () => import("./.loadout/model.rules.ts"),
  canWait: "a ~21 GB download; nothing else needs it",
});

// llama-server as a user service on the GPU named by a word of its name, and
// the warm-up that pre-reads Agent Chat's setup prompt after every start.
export const llamaServer = script("llama-server", {
  description: "llama-server user service, with its prompt-cache warm-up",
  module: () => import("./.loadout/llama-server.ts"),
  rules: () => import("./.loadout/llama-server.rules.ts"),
  runAfter: [llamaCpp, llmModel],
  canWait: "it serves the model, which is later",
});
