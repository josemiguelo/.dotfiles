#!/usr/bin/env bun
// Superwhisper's settings, set through its own CLI (`superwhisper models …`,
// `superwhisper general set …`), never by editing its files: the CLI validates
// each value, refuses to overwrite a change made elsewhere, and applies it at
// once. One key=value per argument:
//   processing=<mode>  cloud, offline or offline_lite. An offline mode's
//                      models (Superwhisper lists what each mode is missing:
//                      `models show`, processingModes) are downloaded first,
//                      one at a time, as Superwhisper only runs one download.
//   <key>=<value>      a general setting with a string value (language, tone),
//                      set after the mode: a language must be one the mode
//                      supports.
// Done = the mode is selected with none of its models missing, and every
// setting has its value.
// usage: superwhisper-settings.ts [check] key=value...
import { $, main } from "#loadout";

type Models = {
  processing: string;
  processingModes: { value: string; missing: string[] }[];
  models: { id: string; download: { state: string }; partialBytes?: number; sizeBytes?: number }[];
};

const models = async (): Promise<Models> => JSON.parse(await $`superwhisper models show`.quiet().text());
const general = async (): Promise<{ config: Record<string, unknown> }> => JSON.parse(await $`superwhisper general show`.quiet().text());

/** The models a processing mode still needs. */
const missing = async (mode: string) => (await models()).processingModes.find((m) => m.value === mode)?.missing ?? [];

/** key=value pairs, refused when one isn't. */
function settings(kvs: string[]) {
  if (kvs.length === 0) throw new Error("usage: superwhisper-settings.ts [check] key=value...");
  return kvs.map((kv) => {
    const at = kv.indexOf("=");
    if (at < 0) throw new Error(`not key=value: ${kv}`);
    return [kv.slice(0, at), kv.slice(at + 1)] as const;
  });
}

/**
 * Downloads one model and waits for it (up to an hour), saying how far it got
 * once a minute: a large one takes a while, and a setup run shouldn't look stuck.
 */
async function download(id: string) {
  for (let tries = 0; ; tries++) {
    const model = (await models()).models.find((m) => m.id === id);
    const state = model?.download.state ?? "";
    if (state === "installed") return console.log(`  ${id}: done`);
    if (state === "missing" || state === "paused") await $`superwhisper models download ${id}`.quiet().nothrow();
    const size = model?.sizeBytes ?? 0;
    if (tries % 6 === 0 && size > 0) {
      const percent = Math.floor(((model?.partialBytes ?? 0) * 100) / size);
      console.log(`  ${id}: ${percent}% of ${Math.floor(size / 1048576)} MB (${state}, ${tries / 6}m)`);
    }
    if (tries + 1 >= 360) throw new Error(`${id} didn't finish downloading`);
    await Bun.sleep(10_000);
  }
}

/** The mode is selected with none of its models missing, and every setting has its value. */
async function applied(kvs: string[]) {
  const m = await models();
  const g = await general();
  return settings(kvs).every(([k, v]) =>
    k === "processing"
      ? m.processing === v && (m.processingModes.find((p) => p.value === v)?.missing ?? []).length === 0
      : String(g.config[k] ?? "") === v,
  );
}

const ready = async (...kvs: string[]) => Bun.which("superwhisper") !== null && (await applied(kvs));

async function install(...kvs: string[]) {
  if (!Bun.which("superwhisper")) throw new Error("superwhisper isn't installed (script.omarchy-default-dictation)");
  const pairs = settings(kvs);
  // The mode first: the other settings are checked against it.
  for (const [, mode] of pairs.filter(([k]) => k === "processing")) {
    for (const id of await missing(mode)) {
      console.log(`downloading Superwhisper's ${id} model`);
      await download(id);
    }
    await $`superwhisper models select ${mode}`.quiet();
  }
  for (const [k, v] of pairs.filter(([k]) => k !== "processing")) {
    await $`superwhisper general set ${k} ${JSON.stringify(v)}`.quiet();
  }
  if (!(await applied(kvs))) throw new Error(`Superwhisper's settings didn't take: ${kvs.join(" ")}`);
}

await main(ready, install);
