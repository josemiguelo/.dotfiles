#!/usr/bin/env bun
// llama-server as a user service, and its warm-up (docs/local-llm.md).
//
// The machine's arguments are the server's: words like VAR=value are its
// environment (GGML_OP_OFFLOAD_MIN_BATCH), the rest its flags, with --model
// <file> naming one of llm-model's files, except `--vulkan-gpu <name>`, which
// is this script's: the GPU to run on, by a word of its name ("Radeon").
// Vulkan numbers the GPUs by which one drives the display, which the T2's
// boot GPU decides, and the dGPU comes up a second after the user session
// starts the unit; so the unit's ExecStartPre (`gpu-env`) waits for that GPU,
// finds its number and hands it to the server as GGML_VK_VISIBLE_DEVICES. A
// fixed number made the server fall back to the CPU, silently, at every boot.
// Two units:
//
// - llama-server.service: the server, logging every prompt it gets into the
//   runtime dir (tmpfs: conversations never reach the disk). When it stops
//   (a restart, a logout, a shutdown, while that dir is still there),
//   `refresh` keeps the setup part of the newest Agent Chat (OpenCode) prompt
//   logged, the tools and instructions before the first user turn, and
//   deletes the logs. It won't start without its model (no restart loop).
// - llama-warmup.service: after every server start, `warmup` replays that
//   setup with today's date so the prompt cache holds it. A new Agent chat then
//   reads only its own message: ~7 s instead of ~90 s. When Copilot, OpenCode
//   or the skills change the setup, the next first message is slow once, and
//   from the next server start the warm-up replays the new one.
//
// check: both units as the arguments make them and enabled (it starts at
// login); stopped is fine (switched off from the tray, llama-toggle), and
// running it must hold memory on its GPU (not fallen back to the CPU), which
// other programs don't crowd (more than SHARE_LIMIT_MIB of theirs on it).
// install: writes what differs and (re)starts the server; the warm-up follows.
// It refuses to without llm-model's verified model.
// usage: llama-server.ts [check|install] <args…>
//        llama-server.ts gpu-env <name> <file>  (llama-server.service, before it starts)
//        llama-server.ts gpu-state              (by hand: the server's GPU and who else is on it)
//        llama-server.ts refresh                (llama-server.service, when it stops)
//        llama-server.ts warmup <base url>      (llama-warmup.service)
import { chmodSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync } from "node:fs";
import { dirname } from "node:path";
import { $, fail, mainCheckoutPath, main, ok, read, waitUntil } from "loadout/script";
import {
  GPU_ENV_UNIT_PATH,
  PROMPTS_UNIT_PATH,
  SERVER_UNIT,
  WARMUP_PROMPT,
  WARMUP_UNIT,
  modelPath,
  promptsDir,
  vulkanDevices,
} from "#llama-cpp";

const USAGE = "usage: llama-server.ts [check|install] [VAR=value…] [--vulkan-gpu <name>] --model <file> [llama-server flags…]";
// How long gpu-env waits for the GPU to come up.
const GPU_WAIT = 90;

/**
 * The arguments as environment and flags, the model's path made absolute.
 * They arrive as the shell split them, so a quoted value with spaces stays one.
 */
function parse(args: string[]) {
  const words = [...args];
  const g = words.indexOf("--vulkan-gpu");
  const gpu = g >= 0 ? words.splice(g, 2)[1] : undefined;
  if (g >= 0 && !gpu) fail(USAGE);
  const env = words.filter((a) => /^[A-Z_][A-Z0-9_]*=/.test(a));
  const flags = words.filter((a) => !env.includes(a));
  const at = flags.findIndex((f) => f === "--model" || f === "-m");
  if (at < 0 || !flags[at + 1]) fail(USAGE);
  flags[at + 1] = modelPath(flags[at + 1]);
  const value = (name: string, fallback: string) => {
    const i = flags.indexOf(name);
    return i >= 0 && flags[i + 1] ? flags[i + 1] : fallback;
  };
  const alias = value("--alias", value("-a", "llama-server"));
  const base = `http://${value("--host", "127.0.0.1")}:${value("--port", "8080")}`;
  return { env, flags, alias, base, gpu, model: flags[at + 1] };
}

/** One ExecStart word: quoted, quotes and backslashes escaped, $ and % doubled (systemd expands both). */
const word = (w: string) =>
  `"${w.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "$$$$").replace(/%/g, "%%")}"`;

/** One Environment= assignment, quoted, % doubled. */
const assignment = (e: string) => `Environment="${e.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/%/g, "%%")}"`;

async function units(args: string[]) {
  const { env, flags, alias, base, gpu, model } = parse(args);
  const server = Bun.which("llama-server");
  if (!server) fail("llama-server isn't installed (llama-cpp)");
  // refresh and warmup run this file outside loadout, so with loadout's bun
  // (the "loadout/script" module is inside loadout), by the main checkout's path.
  const self = await mainCheckoutPath(import.meta.path);
  const loadoutBun = (mode: string, ...rest: string[]) => [process.execPath, "bun", self, mode, ...rest].map(word).join(" ");
  const serverUnit = `# Managed by loadout (llama-server): change the machine's args, not this file.
[Unit]
Description=llama.cpp server (${alias}) for Obsidian Copilot
# Without its model it would fail and restart forever; and a crash loop stops.
ConditionPathExists=${model.replace(/%/g, "%%")}
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
${env.map(assignment).join("\n")}${
    gpu
      ? `
# Waits for the GPU named "${gpu}" and writes its Vulkan number for the server.
ExecStartPre=${loadoutBun("gpu-env", gpu)} "${GPU_ENV_UNIT_PATH}"
EnvironmentFile=-${GPU_ENV_UNIT_PATH}
TimeoutStartSec=3min`
      : ""
  }
ExecStart=${[server, ...flags].map(word).join(" ")} "--log-prompts-dir" "${PROMPTS_UNIT_PATH}"
# The prompt logs are on tmpfs: keep Agent Chat's setup before they're gone.
ExecStopPost=${loadoutBun("refresh")}
Restart=on-failure
RestartSec=5
Nice=5

[Install]
WantedBy=default.target
`;
  const warmupUnit = `# Managed by loadout (llama-server).
[Unit]
Description=Warm llama-server's prompt cache with Agent Chat's setup prompt
After=llama-server.service
PartOf=llama-server.service

[Service]
Type=oneshot
ExecStart=${loadoutBun("warmup", base)}
# Reading ~12K tokens takes ~80 s: past systemd's default start timeout.
TimeoutStartSec=15min
Nice=10

[Install]
WantedBy=llama-server.service
`;
  return { serverUnit, warmupUnit, base, gpu, model };
}

const enabled = (unit: string) => ok($`systemctl --user is-enabled -q ${unit}`);
const active = (unit: string) => ok($`systemctl --user is-active -q ${unit}`);

// Other programs may reserve this much of the server's GPU before it's too
// crowded: with ~2.9 GB of Superwhisper's models beside it, llama-server's
// GPU jobs overran the driver's timeout and it crashed (device lost).
const SHARE_LIMIT_MIB = 256;

type GpuUse = { pdev: string; mib: number };

/** A process's memory per discrete GPU (drm-total-vram in its DRM fdinfo, by PCI device). */
function gpuUse(pid: string): GpuUse[] {
  const byDev = new Map<string, number>();
  let fds: string[];
  try {
    fds = readdirSync(`/proc/${pid}/fdinfo`);
  } catch {
    return [];
  }
  for (const fd of fds) {
    let info: string;
    try {
      info = readFileSync(`/proc/${pid}/fdinfo/${fd}`, "utf8");
    } catch {
      continue;
    }
    const vram = Number(info.match(/^drm-total-vram:\s+(\d+)/m)?.[1] ?? 0);
    const pdev = info.match(/^drm-pdev:\s+(\S+)/m)?.[1];
    if (vram > 0 && pdev) byDev.set(pdev, (byDev.get(pdev) ?? 0) + vram);
  }
  return [...byDev].map(([pdev, kib]) => ({ pdev, mib: Math.round(kib / 1024) }));
}

const serverPid = async () =>
  (await $`systemctl --user show -p MainPID --value llama-server.service`.quiet().nothrow().text()).trim();

/**
 * The server's GPU, if it holds memory on one (llama.cpp on the CPU, or on the
 * Intel iGPU, holds none: that's the silent fallback this catches; a GPU's
 * memory counts even while it sleeps, moved to RAM), and the other processes
 * reserving memory on that GPU, biggest first.
 */
function gpuState(pid: string) {
  const own = pid && pid !== "0" ? gpuUse(pid)[0] : undefined;
  if (!own) return { onGpu: false, others: [] as { name: string; mib: number }[] };
  const others: { name: string; mib: number }[] = [];
  for (const p of readdirSync("/proc")) {
    if (!/^\d+$/.test(p) || p === pid) continue;
    const mib = gpuUse(p).find((u) => u.pdev === own.pdev)?.mib ?? 0;
    if (mib > 0) {
      let name = p;
      try {
        name = `${readFileSync(`/proc/${p}/comm`, "utf8").trim()} (${p})`;
      } catch {}
      others.push({ name, mib });
    }
  }
  return { onGpu: true, others: others.sort((a, b) => b.mib - a.mib) };
}

const crowded = (others: { mib: number }[]) => others.reduce((t, o) => t + o.mib, 0) > SHARE_LIMIT_MIB;

async function ready(...args: string[]) {
  const { serverUnit, warmupUnit, gpu } = await units(args);
  return (
    (await read(SERVER_UNIT)) === serverUnit &&
    (await read(WARMUP_UNIT)) === warmupUnit &&
    (await enabled("llama-server.service")) &&
    (await enabled("llama-warmup.service")) &&
    // Stopped is fine (the tray's switch, llama-toggle, turns it off; it
    // starts again at the next login); running, it must be on its GPU.
    (!(await active("llama-server.service")) ||
      !gpu ||
      ((st) => st.onGpu && !crowded(st.others))(gpuState(await serverPid())))
  );
}

async function healthy(base: string) {
  try {
    return (await fetch(`${base}/health`)).ok;
  } catch {
    return false;
  }
}

async function install(...args: string[]) {
  const { serverUnit, warmupUnit, base, gpu, model } = await units(args);
  // llm-model writes its marker only once the model matches its SHA-256.
  if (!existsSync(model) || !(await read(`${model}.sha256-ok`)).trim()) {
    fail(`${model} isn't downloaded and verified yet: run llm-model first`);
  }
  mkdirSync(dirname(SERVER_UNIT), { recursive: true });
  const changed = (await read(SERVER_UNIT)) !== serverUnit || (await read(WARMUP_UNIT)) !== warmupUnit;
  await Bun.write(SERVER_UNIT, serverUnit);
  await Bun.write(WARMUP_UNIT, warmupUnit);
  await $`systemctl --user daemon-reload`;
  await $`systemctl --user enable llama-server.service llama-warmup.service`.quiet();
  if (changed || !(await active("llama-server.service"))) {
    await $`systemctl --user reset-failed llama-server.service`.nothrow().quiet();
    await $`systemctl --user restart llama-server.service`;
  }
  // Loading ~21 GB takes ~30 s; the warm-up then runs on its own.
  await waitUntil(() => healthy(base), "llama-server to load its model", 2, 150);
  if (gpu) {
    const { onGpu, others } = gpuState(await serverPid());
    if (!onGpu) fail(`llama-server runs without its GPU ("${gpu}"): journalctl --user -u llama-server`);
    if (crowded(others)) {
      const list = others.map((o) => `${o.name} ${o.mib} MiB`).join(", ");
      fail(`llama-server shares its GPU ("${gpu}") with ${list}: move them off it (docs/local-llm.md)`);
    }
  }
}

/**
 * Before the server starts: waits up to GPU_WAIT seconds for the Vulkan device
 * whose description has `name` in it, and writes GGML_VK_VISIBLE_DEVICES=<its
 * number> into file, the unit's EnvironmentFile. Failing (no such GPU) fails
 * the start, and Restart= tries again, rather than run the model on the CPU.
 */
async function gpuEnv(name: string, file: string) {
  const deadline = Date.now() + GPU_WAIT * 1000;
  for (;;) {
    const devices = await vulkanDevices();
    const device = devices.find((d) => d.description.includes(name));
    if (device) {
      mkdirSync(dirname(file), { recursive: true });
      await Bun.write(file, `GGML_VK_VISIBLE_DEVICES=${device.index}\n`);
      console.log(`llama-server: GPU "${name}" is Vulkan${device.index}: ${device.description}`);
      return;
    }
    if (Date.now() >= deadline) {
      const seen = devices.map((d) => `Vulkan${d.index}: ${d.description}`).join("; ") || "none";
      fail(`llama-server: no GPU named "${name}" after ${GPU_WAIT}s (seen: ${seen})`);
    }
    await Bun.sleep(2000);
  }
}

// Qwen's chat template (ChatML): the user's turn starts here. Another model's
// template would need its own marker.
const SETUP_END = "<|im_start|>user\n";

/**
 * The newest logged Agent Chat prompt's setup part (OpenCode's tools carry
 * Copilot's own, obsidian-copilot_*), kept as the warm-up; then every logged
 * prompt goes.
 */
async function refresh() {
  const dir = promptsDir();
  let files: string[] = [];
  try {
    files = readdirSync(dir).map((f) => `${dir}/${f}`);
  } catch {
    return;
  }
  const mtime = (f: string) => statSync(f, { throwIfNoEntry: false })?.mtimeMs ?? 0;
  files.sort((a, b) => mtime(b) - mtime(a));
  for (const file of files) {
    const text = await read(file);
    const end = text.indexOf(SETUP_END);
    if (!text.includes("<tools>") || !text.includes("obsidian-copilot") || end < 0) continue;
    const setup = text.slice(0, end + SETUP_END.length);
    if ((await read(WARMUP_PROMPT)) !== setup) {
      mkdirSync(dirname(WARMUP_PROMPT), { recursive: true });
      await Bun.write(WARMUP_PROMPT, setup);
      chmodSync(WARMUP_PROMPT, 0o600);
      console.log(`llama-warmup: kept a new Agent Chat setup prompt (${setup.length} chars)`);
    }
    break;
  }
  for (const file of files) rmSync(file, { force: true });
}

async function warmup(base: string) {
  // An in-session restart left this session's logs: keep them too.
  await refresh();
  const setup = await read(WARMUP_PROMPT);
  if (!setup) {
    console.log("llama-warmup: no Agent Chat prompt seen yet; the first Agent chat teaches it");
    return;
  }
  await waitUntil(() => healthy(base), "llama-server to load its model", 2, 150);
  // OpenCode writes JS Date.toDateString(), e.g. "Fri Nov 20 2026".
  const today = new Date().toDateString();
  const prompt = setup.replace(/^Today's date: .*$/m, `Today's date: ${today}`);
  const started = Date.now();
  const response = await fetch(`${base}/completion`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt, n_predict: 1, cache_prompt: true, temperature: 0 }),
  });
  if (!response.ok) fail(`llama-warmup: ${response.status} ${await response.text()}`);
  const { timings } = (await response.json()) as { timings: { prompt_n: number } };
  console.log(`llama-warmup: read ${timings.prompt_n} tokens in ${Math.round((Date.now() - started) / 1000)} s`);
}

if (process.argv[2] === "gpu-state") {
  // What check sees: the server on its GPU, and who else reserves memory there.
  console.log(JSON.stringify(gpuState(await serverPid()), null, 2));
} else if (process.argv[2] === "gpu-env") {
  if (!process.argv[3] || !process.argv[4]) fail("usage: llama-server.ts gpu-env <name> <file>");
  await gpuEnv(process.argv[3], process.argv[4]);
} else if (process.argv[2] === "refresh") {
  await refresh();
} else if (process.argv[2] === "warmup") {
  await warmup(process.argv[3] || "http://127.0.0.1:8080");
} else {
  await main(ready, install);
}
