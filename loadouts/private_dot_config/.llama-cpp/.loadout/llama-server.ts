#!/usr/bin/env bun
// llama-server as a user service, and its warm-up (docs/local-llm.md).
//
// The machine's arguments are the server's: words like VAR=value are its
// environment (GGML_VK_VISIBLE_DEVICES, GGML_OP_OFFLOAD_MIN_BATCH), the rest
// its flags, with --model <file> naming one of llm-model's files. Two units:
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
// check: both units as the arguments make them, enabled, and the server running.
// install: writes what differs and (re)starts the server; the warm-up follows.
// It refuses to without llm-model's verified model.
// usage: llama-server.ts [check|install] <args…>
//        llama-server.ts refresh              (llama-server.service, when it stops)
//        llama-server.ts warmup <base url>    (llama-warmup.service)
import { chmodSync, existsSync, mkdirSync, readdirSync, rmSync, statSync } from "node:fs";
import { dirname } from "node:path";
import { $, fail, mainCheckoutPath, main, ok, read, waitUntil } from "loadout/script";
import { PROMPTS_UNIT_PATH, SERVER_UNIT, WARMUP_PROMPT, WARMUP_UNIT, modelPath, promptsDir } from "#llama-cpp";

const USAGE = "usage: llama-server.ts [check|install] [VAR=value…] --model <file> [llama-server flags…]";

/**
 * The arguments as environment and flags, the model's path made absolute.
 * They arrive as the shell split them, so a quoted value with spaces stays one.
 */
function parse(args: string[]) {
  const env = args.filter((a) => /^[A-Z_][A-Z0-9_]*=/.test(a));
  const flags = args.filter((a) => !env.includes(a));
  const at = flags.findIndex((f) => f === "--model" || f === "-m");
  if (at < 0 || !flags[at + 1]) fail(USAGE);
  flags[at + 1] = modelPath(flags[at + 1]);
  const value = (name: string, fallback: string) => {
    const i = flags.indexOf(name);
    return i >= 0 && flags[i + 1] ? flags[i + 1] : fallback;
  };
  const alias = value("--alias", value("-a", "llama-server"));
  const base = `http://${value("--host", "127.0.0.1")}:${value("--port", "8080")}`;
  return { env, flags, alias, base, model: flags[at + 1] };
}

/** One ExecStart word: quoted, quotes and backslashes escaped, $ and % doubled (systemd expands both). */
const word = (w: string) =>
  `"${w.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "$$$$").replace(/%/g, "%%")}"`;

/** One Environment= assignment, quoted, % doubled. */
const assignment = (e: string) => `Environment="${e.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/%/g, "%%")}"`;

async function units(args: string[]) {
  const { env, flags, alias, base, model } = parse(args);
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
${env.map(assignment).join("\n")}
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
  return { serverUnit, warmupUnit, base, model };
}

const enabled = (unit: string) => ok($`systemctl --user is-enabled -q ${unit}`);
const active = (unit: string) => ok($`systemctl --user is-active -q ${unit}`);

async function ready(...args: string[]) {
  const { serverUnit, warmupUnit } = await units(args);
  return (
    (await read(SERVER_UNIT)) === serverUnit &&
    (await read(WARMUP_UNIT)) === warmupUnit &&
    (await enabled("llama-server.service")) &&
    (await enabled("llama-warmup.service")) &&
    (await active("llama-server.service"))
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
  const { serverUnit, warmupUnit, base, model } = await units(args);
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

if (process.argv[2] === "refresh") {
  await refresh();
} else if (process.argv[2] === "warmup") {
  await warmup(process.argv[3] || "http://127.0.0.1:8080");
} else {
  await main(ready, install);
}
