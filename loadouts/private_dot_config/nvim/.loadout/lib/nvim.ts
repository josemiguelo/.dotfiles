// Headless Neovim for loadout's nvim scripts: the lazy.nvim plugins
// (plugins.ts, outdated-plugins.ts) and Mason's kotlin-lsp
// (mason-kotlin-lsp.ts, outdated-kotlin-lsp.ts). Each asks a Lua helper
// beside it (plugins.lua, mason.lua) under `nvim --headless`, which writes its
// answer to a file: its lines, then a __LOADOUT_NVIM_OK__ sentinel, or a
// __LOADOUT_NVIM_ERR__ <reason> line. A hung nvim is killed after a time
// limit, so it can never stall loadout.
import { existsSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { $, read } from "loadout/script";

const HOME = process.env.HOME!;
const DATA = process.env.XDG_DATA_HOME || `${HOME}/.local/share`;
const CONFIG = process.env.XDG_CONFIG_HOME || `${HOME}/.config`;
const OK = "__LOADOUT_NVIM_OK__";
const ERR = "__LOADOUT_NVIM_ERR__ ";

/**
 * PATH with ~/.local/bin and mise's shims first, for the neovim the mise
 * config pins (nightly) when this runs outside a shell that activated mise.
 */
const PATH = [`${HOME}/.local/bin`, `${process.env.MISE_DATA_DIR || `${DATA}/mise`}/shims`, process.env.PATH].join(":");
const nvim = () => Bun.which("nvim", { PATH });

/**
 * Commands run from $HOME: nvim runs through mise's shim, and from the repo's
 * cwd mise would also find the dotfiles' copy of its config in a parent.
 */
const inHome = (command: ReturnType<typeof $>) => command.cwd(HOME).env({ ...process.env, PATH });

type Answer = { ok: true; lines: string[] } | { ok: false; reason: string };

/** nvim --headless with args and env, its answer read from the file outVar names. */
async function ask(args: string[], env: Record<string, string>, outVar: string, seconds: number): Promise<Answer> {
  const bin = nvim();
  if (!bin) return { ok: false, reason: "nvim not found" };
  const dir = await mkdtemp(join(tmpdir(), "loadout-nvim-"));
  const out = join(dir, "answer");
  try {
    const proc = Bun.spawn([bin, "--headless", ...args], {
      cwd: HOME,
      env: { ...process.env, PATH, ...env, [outVar]: out },
      stdin: "ignore",
      stdout: "ignore",
      stderr: "ignore",
      timeout: seconds * 1000,
    });
    await proc.exited;
    const lines = (await read(out)).split("\n");
    if (lines.includes(OK)) return { ok: true, lines: lines.filter((l) => l !== OK && l.trim() !== "") };
    const err = lines.find((l) => l.startsWith(ERR));
    return { ok: false, reason: err ? err.slice(ERR.length) : "nvim did not answer" };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

// ─── lazy.nvim plugins ─────────────────────────────────────────────────

const LOCK = `${CONFIG}/nvim/lazy-lock.json`;

/**
 * Lazy rewrites the lockfile whenever it installs, and any nvim start installs
 * what's missing: on a fresh machine, the plugins LazyVim's imports name only
 * once LazyVim is cloned land on their newest commits, and the lock is
 * rewritten to match. Only `update` may move pins, so every other nvim run
 * puts the lock back as it found it, and the check compares the disk with that
 * copy (LOADOUT_NVIM_LOCK), not with Lazy's rewritten one.
 */
async function withLock<T>(keep: boolean, work: (saved: string) => Promise<T>): Promise<T> {
  const dir = await mkdtemp(join(tmpdir(), "loadout-lock-"));
  const saved = join(dir, "lazy-lock.json");
  await Bun.write(saved, "");
  try {
    if (keep && existsSync(LOCK)) await $`cp -p ${LOCK} ${saved}`;
    const result = await work(saved);
    if (keep && Bun.file(saved).size > 0) await $`cp -p ${saved} ${LOCK}`;
    return result;
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

/** plugins.lua (`lua`) in mode, on item: every mode but update keeps the lock. */
const askLazy = (lua: string, mode: string, item = "") =>
  withLock(mode !== "update", (saved) =>
    ask(["-n", "-c", `luafile ${lua}`, "-c", "qa!"], { LOADOUT_NVIM_MODE: mode, LOADOUT_NVIM_ITEM: item, LOADOUT_NVIM_LOCK: saved }, "LOADOUT_NVIM_OUT", 120),
  );

/** Does the disk match the lock: every plugin the spec enables cloned, on its locked commit. */
export async function lazyCheck(lua: string): Promise<boolean> {
  if (!existsSync(LOCK)) {
    console.error("lazy-lock.json not found");
    return false;
  }
  if (!nvim()) {
    console.error("nvim not found");
    return false;
  }
  const answer = await askLazy(lua, "check");
  if (!answer.ok) {
    console.log(`could not ask Lazy: ${answer.reason}`);
    return false;
  }
  for (const line of answer.lines) {
    const [kind, name, head, locked] = line.split(/\s+/);
    if (kind === "missing") console.log(`missing plugin: ${name}`);
    else if (kind === "off-lock") console.log(`plugin off its lock: ${name} (installed ${head}, locked ${locked})`);
  }
  return answer.lines.length === 0;
}

/** Make it so: a plain start (it installs every plugin the spec names, those behind LazyVim's imports too), then Lazy's restore. */
export async function lazyInstall() {
  if (!nvim()) throw new Error("nvim not found");
  await withLock(true, async () => {
    await inHome($`nvim --headless +qa`);
  });
  await withLock(true, async () => {
    await inHome($`nvim --headless ${"+Lazy! restore"} +qa`);
  });
}

/**
 * The plugins Lazy calls outdated, `<plugin> <current> <candidate>` lines.
 * Silent with no neovim or lazy.nvim here; a FAILED row when Lazy couldn't
 * answer, so a broken oracle never reads as "nothing outdated".
 */
export async function lazyOutdated(lua: string) {
  if (!nvim() || !existsSync(`${DATA}/nvim/lazy/lazy.nvim`)) return;
  const answer = await askLazy(lua, "outdated");
  if (!answer.ok) console.log(`nvim-plugins-oracle FAILED FAILED ${answer.reason}`);
  else for (const line of answer.lines) console.log(line);
}

/**
 * Moves one plugin to what lazyOutdated reported: Lazy's own update, so Lazy
 * stays the only writer of the pins. It moves the pin in the lockfile chezmoi
 * APPLIES: chezmoi reports the drift until `chezmoi re-add` brings it to the
 * dotfiles source.
 */
export async function lazyUpdate(lua: string, plugin: string) {
  if (!nvim()) throw new Error("nvim not found");
  const answer = await askLazy(lua, "update", plugin);
  if (!answer.ok) throw new Error(`could not update ${plugin}: ${answer.reason}`);
  for (const line of answer.lines) console.log(line);
}

// ─── Mason ─────────────────────────────────────────────────────────────

const MASON_NVIM = `${DATA}/nvim/lazy/mason.nvim`;

/** Mason's receipt is what makes a package installed; no nvim needed to see it. */
export const masonHas = (pkg: string) => existsSync(`${DATA}/nvim/mason/packages/${pkg}/mason-receipt.json`);

/** mason.lua (`lua`) in mode, for pkg; installs get 15 minutes (kotlin-lsp is ~500MB). */
function askMason(lua: string, mode: string, pkg: string): Promise<Answer> {
  if (!existsSync(MASON_NVIM)) return Promise.resolve({ ok: false, reason: "mason.nvim isn't cloned (script.nvim-plugins)" });
  return ask(
    ["--clean", "--cmd", `set rtp^=${MASON_NVIM}`, "-c", `luafile ${lua}`],
    { LOADOUT_MASON_MODE: mode, LOADOUT_MASON_PACKAGE: pkg },
    "LOADOUT_MASON_OUT",
    mode === "install" ? 900 : 120,
  );
}

/** Mason installs pkg's latest (an update when it's installed). */
export async function masonInstall(lua: string, pkg: string) {
  if (!nvim()) throw new Error("nvim not found");
  const answer = await askMason(lua, "install", pkg);
  if (!answer.ok) throw new Error(`Mason couldn't install ${pkg}: ${answer.reason}`);
  if (!masonHas(pkg)) throw new Error(`Mason reported ${pkg} installed, but its receipt isn't there`);
}

/**
 * `<pkg> <installed> <latest>` when Mason has a newer one. Silent where there's
 * nothing to report on; a FAILED row when Mason couldn't answer, so a broken
 * check never reads as up to date.
 */
export async function masonOutdated(lua: string, pkg: string) {
  if (!nvim() || !masonHas(pkg)) return;
  const answer = await askMason(lua, "versions", pkg);
  if (!answer.ok) {
    console.log(`${pkg} FAILED FAILED ${answer.reason}`);
    return;
  }
  const [installed, latest] = (answer.lines[0] ?? "").split(/\s+/);
  if (installed !== latest) console.log(`${pkg} ${installed} ${latest}`);
}
