// Superwhisper's offline workers on one GPU, by PCI id (docs/local-llm.md): its
// ggml picks the discrete GPU when there is one, and on the T2 its models
// reserve ~2.9 GB of the Radeon's 4 GB, which llama-server needs (with both on
// it, llama-server's GPU jobs overran the driver's timeout and it crashed).
// A drop-in for superwhisper.service sets Mesa's device-select layer
// (vulkan-mesa-implicit-layers) to show its workers that GPU alone, however
// Vulkan numbers the GPUs this boot.
// check: the drop-in as the options make it, and the running service started
// with it. install: writes it and restarts the service (a dictation in progress
// is cut short).
import { mkdirSync, readFileSync } from "node:fs";
import { dirname } from "node:path";
import { $, succeeds, read } from "loadout/script";
import type { Options } from "./gpu.rules.ts";

const DROPIN = `${process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`}/systemd/user/superwhisper.service.d/gpu.conf`;

function dropin(id: string) {
  return `# Managed by loadout (superwhisper-gpu): change the machine's args, not this file.
[Service]
Environment=MESA_VK_DEVICE_SELECT=${id}
Environment=MESA_VK_DEVICE_SELECT_FORCE_DEFAULT_DEVICE=1
`;
}

/** The running daemon's environment has the device selection (it started after the drop-in). */
async function running(id: string) {
  const pid = (await $`systemctl --user show -p MainPID --value superwhisper.service`.quiet().nothrow().text()).trim();
  if (!pid || pid === "0") return false;
  try {
    return readFileSync(`/proc/${pid}/environ`, "utf8").split("\0").includes(`MESA_VK_DEVICE_SELECT=${id}`);
  } catch {
    return false;
  }
}

export async function check({ pciId }: Options) {
  return (await read(DROPIN)) === dropin(pciId) && (await running(pciId));
}

export async function install({ pciId }: Options) {
  mkdirSync(dirname(DROPIN), { recursive: true });
  await Bun.write(DROPIN, dropin(pciId));
  await $`systemctl --user daemon-reload`;
  if (await succeeds($`systemctl --user is-enabled -q superwhisper.service`)) {
    await $`systemctl --user restart superwhisper.service`;
  }
}
