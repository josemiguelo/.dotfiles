// The Copilot plugin (github.com/logancyang/obsidian-copilot) in a vault, on
// the local llama-server and Miyo (docs/local-llm.md).
//
// check: the plugin installed and enabled, and its settings holding
//   - the llama.cpp provider (that base URL) and its model, with the server's
//     context size, which Copilot passes on to OpenCode (it assumes 200K
//     otherwise, and the conversation overflows without warning);
//   - that model first in Quick Chat's and OpenCode's lists, and Agent Chat's
//     default: without one, Copilot hands OpenCode the first enabled model,
//     and OpenCode adds cloud models (OpenCode Zen) of its own to that list;
//   - Miyo's search on, for Copilot and for the agents, with that many results.
// install: whichever isn't: the plugin from its pinned release, checked
// against SHA-256s, only when it's missing (Obsidian's own updater moves it
// after that), then those settings merged into its data.json (a copy kept as
// data.json.bak); Copilot fills the rest with its defaults. Obsidian rewrites
// plugin settings while it runs, so install waits for it to be quit
// (OBSIDIAN_WAIT seconds, default 900; 0 doesn't wait).
import { copyFileSync, existsSync, mkdirSync, renameSync, rmSync } from "node:fs";
import { fail, read } from "loadout/script";
import { obsidianRunning, seconds, vaultPath, waitForUser } from "#obsidian";
import type { Options } from "./copilot.rules.ts";

// The release installed when the plugin is missing, its files' SHA-256s, and
// the settings version it writes for a data.json it creates (one without it
// gets every migration from v0). Its settings layout (V4: providers,
// configuredModels, backends, agentMode) is what this script writes.
const VERSION = "4.0.20";
const RELEASE = `https://github.com/logancyang/obsidian-copilot/releases/download/${VERSION}`;
const FILES: Record<string, string> = {
  "main.js": "dced23553071534303d0663e76b9c5efaa75224659970e1b920bfcfd1b5204d6",
  "styles.css": "087db66a2fb0fa42eaead8307e789934919b7e871304dd934f81023ab5c58685",
  // Last: its presence is what says the plugin is installed.
  "manifest.json": "8e13c8f8642e2e74905ea22fe3831deb0346b07fda1c52ee252cffd84ed6ab9a",
};
const SETTINGS_VERSION = 16;
// Copilot names providers and models by id; these are the ids (and times) it
// gave them on the first machine, kept so its chats' model references stay valid.
const PROVIDER = "f0d7979b-28b5-406b-a93f-fdb4fac130cc";
const PROVIDER_ADDED = 1795193611422;
const MODEL = "6527df27-5b4a-472d-a684-b2805cac2fd1";
const MODEL_ADDED = 1795193611459;
const LISTS = ["chat", "opencode"];

type Info = { id: string; limits?: { context?: number } } & Record<string, unknown>;
type Settings = {
  providers?: Record<string, { baseUrl?: string } & Record<string, unknown>>;
  configuredModels?: ({ configuredModelId: string; providerId: string; info: Info } & Record<string, unknown>)[];
  backends?: Record<string, { enabledModels?: string[] } & Record<string, unknown>>;
  agentMode?: { backends?: { opencode?: { defaultModel?: { baseModelId?: string; effort?: unknown } } & Record<string, unknown> } & Record<string, unknown> } & Record<string, unknown>;
  enableMiyo?: boolean;
  enableMiyoSearchSkill?: boolean;
  miyoSearchMaxResults?: number;
  settingsVersion?: number;
} & Record<string, unknown>;

function resolved({ vault, baseUrl, model, context, miyoResults }: Options) {
  const config = `${vaultPath(vault)}/.obsidian`;
  return { config, plugin: `${config}/plugins/copilot`, baseUrl, model, context, miyoResults };
}

type Wanted = ReturnType<typeof resolved>;

const json = async <T>(path: string, fallback: T): Promise<T> => {
  const text = await read(path);
  return text ? (JSON.parse(text) as T) : fallback;
};

/** Agent Chat's model, as Copilot names it: <provider id>/<model>. */
const agentModel = (model: string) => `${PROVIDER}/${model}`;

function settingsHold(s: Settings, { baseUrl, model, context, miyoResults }: Wanted) {
  return (
    s.providers?.[PROVIDER]?.baseUrl === baseUrl &&
    (s.configuredModels ?? []).some(
      (m) => m.configuredModelId === MODEL && m.info?.id === model && m.info?.limits?.context === context,
    ) &&
    LISTS.every((b) => s.backends?.[b]?.enabledModels?.[0] === MODEL) &&
    s.agentMode?.backends?.opencode?.defaultModel?.baseModelId === agentModel(model) &&
    s.enableMiyo === true &&
    s.enableMiyoSearchSkill === true &&
    s.miyoSearchMaxResults === miyoResults
  );
}

export async function check(options: Options) {
  const wanted = resolved(options);
  if (!existsSync(`${wanted.plugin}/manifest.json`)) return false;
  if (!(await json<string[]>(`${wanted.config}/community-plugins.json`, [])).includes("copilot")) return false;
  return settingsHold(await json<Settings>(`${wanted.plugin}/data.json`, {}), wanted);
}

/** The release's files, each checked before it's put in place, the manifest last. */
async function installPlugin(plugin: string) {
  mkdirSync(plugin, { recursive: true });
  for (const [file, sha256] of Object.entries(FILES)) {
    const response = await fetch(`${RELEASE}/${file}`);
    if (!response.ok) fail(`${RELEASE}/${file}: ${response.status} ${response.statusText}`);
    const part = `${plugin}/${file}.part`;
    await Bun.write(part, response);
    const got = new Bun.CryptoHasher("sha256").update(await Bun.file(part).arrayBuffer()).digest("hex");
    if (got !== sha256) {
      rmSync(part, { force: true });
      fail(`Copilot ${VERSION}'s ${file} doesn't match its SHA-256`);
    }
    renameSync(part, `${plugin}/${file}`);
  }
}

export async function install(options: Options) {
  const wanted = resolved(options);
  const { config, plugin, baseUrl, model, context, miyoResults } = wanted;
  // obsidian-vault, which runs first, waits for Sync to bring it.
  if (!existsSync(config)) fail(`${config} isn't there yet: run obsidian-vault first`);
  await waitForUser("obsidian-copilot", () => !obsidianRunning(), {
    wait: seconds("OBSIDIAN_WAIT", 900),
    every: 2,
    instructions: `Quit Obsidian (Ctrl+Q) so Copilot can be configured (waiting up to {wait}).
    This goes on by itself once it's closed; open it again afterwards.`,
  });

  if (!existsSync(`${plugin}/manifest.json`)) await installPlugin(plugin);

  const enabledPath = `${config}/community-plugins.json`;
  const enabled = await json<string[]>(enabledPath, []);
  if (!enabled.includes("copilot")) await Bun.write(enabledPath, `${JSON.stringify([...enabled, "copilot"], null, 2)}\n`);

  const dataPath = `${plugin}/data.json`;
  const fresh = !existsSync(dataPath);
  if (!fresh) copyFileSync(dataPath, `${dataPath}.bak`);
  const s = await json<Settings>(dataPath, {});
  if (fresh) s.settingsVersion = SETTINGS_VERSION;
  s.providers = {
    ...s.providers,
    [PROVIDER]: {
      ...s.providers?.[PROVIDER],
      providerType: "openai-compatible",
      displayName: "llama.cpp",
      baseUrl,
      enableCors: false,
      requiresApiKey: false,
      origin: { kind: "byok" },
      providerId: PROVIDER,
      addedAt: PROVIDER_ADDED,
      apiKeyKeychainId: null,
    },
  };
  // Replaced where it is, so data.json changes no more than it must.
  const models = s.configuredModels ?? [];
  const current = models.find((m) => m.configuredModelId === MODEL);
  const entry = {
    configuredModelId: MODEL,
    providerId: PROVIDER,
    info: { ...current?.info, id: model, displayName: model, limits: { ...current?.info?.limits, context } },
    configuredAt: MODEL_ADDED,
  };
  s.configuredModels = current
    ? models.map((m) => (m.configuredModelId === MODEL ? { ...m, ...entry } : m))
    : [...models, entry];
  s.backends = s.backends ?? {};
  for (const b of LISTS) {
    const others = (s.backends[b]?.enabledModels ?? []).filter((m) => m !== MODEL);
    s.backends[b] = { ...s.backends[b], enabledModels: [MODEL, ...others] };
  }
  const agent = s.agentMode ?? {};
  const backends = agent.backends ?? {};
  s.agentMode = {
    ...agent,
    backends: { ...backends, opencode: { ...backends.opencode, defaultModel: { baseModelId: agentModel(model), effort: null } } },
  };
  s.enableMiyo = true;
  s.enableMiyoSearchSkill = true;
  s.miyoSearchMaxResults = miyoResults;
  await Bun.write(dataPath, `${JSON.stringify(s, null, 2)}\n`);
}
