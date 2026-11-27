#!/usr/bin/env bun
// Benchmark a model's CPU/GPU splits with llama-bench, by hand (not a loadout
// step); the numbers behind the machine's llama-server args are in
// docs/local-llm.md. Stops llama-server while it runs (they'd share the VRAM)
// and starts it again after.
//   loadout bun bench.ts <model file> [vulkan device]          the default sweep
//   loadout bun bench.ts <model file> <device> <llama-bench args…>  one config
import { $ } from "loadout/script";
import { modelPath } from "#llama-cpp";

const [model, device = "1", ...custom] = process.argv.slice(2);
if (!model) {
  console.error("usage: bench.ts <model file> [vulkan device] [llama-bench args…]");
  process.exit(1);
}

const SWEEP = [
  ["-ngl", "0"], // CPU only
  ["-ngl", "99", "--n-cpu-moe", "99"], // non-expert weights on the GPU, experts in RAM
  ["-ngl", "99", "--n-cpu-moe", "99", "-ub", "2048", "-b", "2048"], // + big batches
  ["-ngl", "99", "--n-cpu-moe", "99", "-ub", "4096", "-b", "4096"], // + bigger batches
];

const wasActive = (await $`systemctl --user is-active -q llama-server`.nothrow()).exitCode === 0;
if (wasActive) await $`systemctl --user stop llama-server`;
try {
  for (const config of custom.length ? [custom] : SWEEP) {
    console.log(`\n==> llama-bench ${config.join(" ")}`);
    await $`llama-bench -m ${modelPath(model)} -t 8 -fa on -p 4096 -n 128 -r 1 -o md ${config}`
      .env({ ...process.env, GGML_VK_VISIBLE_DEVICES: device })
      .nothrow();
  }
} finally {
  if (wasActive) await $`systemctl --user start llama-server`;
}
