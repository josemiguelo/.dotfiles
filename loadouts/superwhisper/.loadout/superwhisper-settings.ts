// Superwhisper's settings, set through its own CLI (`superwhisper models …`,
// `superwhisper general set …`), never by editing its files: the CLI validates
// each value, refuses to overwrite a change made elsewhere, and applies it at
// once. The processing mode first (an offline one's models are downloaded
// before it's selected, one at a time, as Superwhisper only runs one download;
// it lists what each mode is missing: `models show`, processingModes), then
// the general settings: a language must be one the mode supports.
// Done = the mode is selected with none of its models missing, and every
// setting has its value.
import { $ } from "loadout/script";
import type { Options } from "./superwhisper-settings.rules.ts";

type Models = {
  processing: string;
  processingModes: { value: string; missing: string[] }[];
  models: { id: string; download: { state: string }; partialBytes?: number; sizeBytes?: number }[];
};

const models = async (): Promise<Models> => JSON.parse(await $`superwhisper models show`.quiet().text());
const general = async (): Promise<{ config: Record<string, unknown> }> => JSON.parse(await $`superwhisper general show`.quiet().text());

/** The models a processing mode still needs. */
const missing = async (mode: string) => (await models()).processingModes.find((m) => m.value === mode)?.missing ?? [];

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
async function applied({ processing, general: wanted = {} }: Options) {
  const m = await models();
  const g = await general();
  return (
    m.processing === processing &&
    (m.processingModes.find((p) => p.value === processing)?.missing ?? []).length === 0 &&
    Object.entries(wanted).every(([k, v]) => String(g.config[k] ?? "") === v)
  );
}

export const check = async (options: Options) => Bun.which("superwhisper") !== null && (await applied(options));

export async function install(options: Options) {
  if (!Bun.which("superwhisper")) throw new Error("superwhisper isn't installed (script.omarchy-default-dictation)");
  // The mode first: the other settings are checked against it.
  for (const id of await missing(options.processing)) {
    console.log(`downloading Superwhisper's ${id} model`);
    await download(id);
  }
  await $`superwhisper models select ${options.processing}`.quiet();
  for (const [k, v] of Object.entries(options.general ?? {})) {
    await $`superwhisper general set ${k} ${JSON.stringify(v)}`.quiet();
  }
  if (!(await applied(options))) throw new Error(`Superwhisper's settings didn't take: ${JSON.stringify(options)}`);
}
