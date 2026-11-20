// llama.cpp: the local LLM that Obsidian Copilot talks to (docs/local-llm.md).
// The model and the server's tuning are the hardware's, so the profile of the
// machines with that hardware names them (args).
import { omarchy, program, script } from "loadout";

// llama.cpp's GPU backend for the T2's Radeon (RDNA1: no ROCm support).
export const ggmlVulkan = program("ggml-vulkan", {
  description: "ggml's Vulkan backend: llama.cpp on the GPU",
  install: [omarchy],
});

export const llamaCpp = program("llama-cpp", {
  description: "llama.cpp: local LLM inference and its OpenAI-compatible server",
  dependsOn: [ggmlVulkan],
  install: [omarchy],
});

// One GGUF from Hugging Face at a pinned commit, checked against its SHA-256:
// args(llmModel, "<hf repo>", "<commit>", "<file>", "<sha256>").
export const llmModel = script("llm-model", {
  description: "the local LLM's GGUF model, from Hugging Face",
  managedBy: ".loadout/model.ts",
  later: "a ~21 GB download; nothing else needs it",
});

// llama-server as a user service, and the warm-up that pre-reads Agent Chat's
// setup prompt after every start:
// args(llamaServer, "VAR=value"…, "--model <file>", "<llama-server flags>"…).
export const llamaServer = script("llama-server", {
  description: "llama-server user service, with its prompt-cache warm-up",
  managedBy: ".loadout/llama-server.ts",
  runAfter: [llamaCpp, llmModel],
  later: "it serves the model, which is later",
});
