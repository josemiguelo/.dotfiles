// What the Omarchy scripts share (Bun): talking to the Omarchy shell, the
// bar's widgets, plugins installed from git, entries of our own in the
// Omarchy menu, and local replacements of Omarchy commands.
import { accessSync, constants, readdirSync, statSync } from "node:fs";
import { mkdir, rename } from "node:fs/promises";
import { dirname } from "node:path";
import { $, ok, read } from "#loadout";
import { HOME, probe } from "#hypr";

/** A JSON file's value, or null when it's missing or not JSON. */
export async function readJson(path: string): Promise<any> {
  try {
    return JSON.parse(await read(path));
  } catch {
    return null;
  }
}

/** Writes path in a single rename, so a reader watching it never sees half a file. */
export async function replaceFile(path: string, text: string) {
  await mkdir(dirname(path), { recursive: true });
  const tmp = `${path}.${process.pid}.tmp`;
  await Bun.write(tmp, text);
  await rename(tmp, path);
}

// ── The shell ──────────────────────────────────────────────────────────────
// omarchy-shell (and `omarchy plugin …`, which goes through it) gives each
// call OMARCHY_SHELL_IPC_TIMEOUT, 2s by default, and the shell can take
// longer while it hot-reloads plugins or restarts (omarchy-bar-own-widgets
// restarts it after installing widgets), so a script run right after reads
// "omarchy-shell is not responding", or a plugin as not enabled. Calls get
// 10s here.
process.env.OMARCHY_SHELL_IPC_TIMEOUT ||= "10s";

/**
 * Waits (up to 30s) until the shell answers at all. A check asks once and
 * gives up at once: with no shell running (logged out, over ssh) every status
 * would otherwise stall 30s per script. The waiting is for installs, which
 * run right after a restart.
 */
export async function shellReady(mode: "check" | "install" = "install") {
  const tries = mode === "check" ? 1 : 30;
  for (let i = 1; ; i++) {
    if (await ok($`omarchy-shell shell ping`)) return;
    if (i >= tries) throw new Error("omarchy-shell isn't answering");
    await Bun.sleep(1000);
  }
}

// ── Bar widgets ────────────────────────────────────────────────────────────
// Their entries in Omarchy's bar layout (~/.config/omarchy/shell.json,
// bar.layout), and the settings a widget's file lists, set with
// `omarchy bar set` into its entry (keys the file doesn't list are left as
// they are).

export const SHELL_JSON = `${HOME}/.config/omarchy/shell.json`;

/** Every widget entry on the bar, section by section in order. */
const barEntries = (shell: any): any[] => Object.values(shell?.bar?.layout ?? {}).flat();

/** Enabled as `omarchy plugin list` says. A bar widget counts as enabled only while it is on the bar. */
export async function widgetEnabled(id: string): Promise<boolean> {
  const list = await $`omarchy plugin list --json`.quiet().nothrow();
  try {
    return JSON.parse(list.stdout.toString()).some((p: any) => p.id === id && p.enabled);
  } catch {
    return false;
  }
}

/** In any section of the bar's layout. */
export const widgetOnBar = async (id: string) => barEntries(await readJson(SHELL_JSON)).some((e) => e?.id === id);

/** Every key settingsFile lists has that value in the widget's entry. No file, nothing to check. */
export async function widgetConfigured(id: string, settingsFile: string): Promise<boolean> {
  if (!(await Bun.file(settingsFile).exists())) return true;
  const shell = await readJson(SHELL_JSON);
  if (!shell) return false;
  const entry = barEntries(shell).find((e) => e?.id === id) ?? {};
  return Object.entries(await readJson(settingsFile)).every(([key, value]) => Bun.deepEquals(entry[key], value));
}

/** Sets every key settingsFile lists. */
export async function widgetConfigure(id: string, settingsFile: string) {
  if (!(await Bun.file(settingsFile).exists())) return;
  for (const [key, value] of Object.entries(await readJson(settingsFile))) {
    await $`omarchy bar set ${id} ${key} ${JSON.stringify(value)} --json`.quiet();
  }
}

// ── Plugins from git ───────────────────────────────────────────────────────
// ~/.config/omarchy/plugins/<id>, installed by omarchy-plugins. Nothing
// updates those checkouts but `omarchy plugin update` (or `loadout
// outdated`), while the scripts building on them follow upstream: a checkout
// left behind shows up as a missing file or a setting the plugin doesn't
// know yet. omarchy-plugin-update only fast-forwards (`git merge --ff-only
// FETCH_HEAD` on whatever branch is checked out), so a checkout with commits
// of its own, or uncommitted changes, gets told to catch up by hand instead.

export const PLUGINS = `${HOME}/.config/omarchy/plugins`;

/** The plugin checkouts: folders of PLUGINS that are git clones (hidden ones aside), by full path. */
export function pluginCheckouts(): string[] {
  let names: string[] = [];
  try {
    names = readdirSync(PLUGINS).sort();
  } catch {}
  return names.filter((n) => !n.startsWith(".")).map((n) => `${PLUGINS}/${n}`).filter((dir) => isDir(`${dir}/.git`));
}

const isDir = (path: string) => statSync(path, { throwIfNoEntry: false })?.isDirectory() ?? false;

/**
 * Why `omarchy plugin update` can't fast-forward the checkout in dir to its
 * remote's HEAD ("N commit(s) of its own on <branch>", "uncommitted
 * changes"), or "" when it can. Reads FETCH_HEAD, so it comes right after a
 * `git fetch origin HEAD` there.
 */
export async function pluginDiverged(dir: string): Promise<string> {
  const ahead = Number((await $`git -C ${dir} rev-list --count FETCH_HEAD..HEAD`.quiet().nothrow()).stdout.toString().trim()) || 0;
  if (ahead > 0) {
    const branch = (await $`git -C ${dir} branch --show-current`.quiet().nothrow()).stdout.toString().trim();
    return `${ahead} commit(s) of its own${branch ? ` on ${branch}` : ""}`;
  }
  const status = await $`git -C ${dir} status --porcelain`.quiet().nothrow();
  return status.stdout.toString().trim() ? "uncommitted changes" : "";
}

/**
 * On stderr, a line for each id that is a git checkout behind its remote's
 * HEAD, for a script to print after it fails; only then, since it fetches
 * each one. Ids without one (Omarchy's built-ins, clones) are skipped.
 */
export async function pluginUpdateHint(...ids: string[]) {
  for (const id of ids) {
    const dir = `${PLUGINS}/${id}`;
    if (!isDir(`${dir}/.git`)) continue;
    if (!(await ok($`git -C ${dir} fetch --quiet origin HEAD`))) continue;
    const behind = Number((await $`git -C ${dir} rev-list --count HEAD..FETCH_HEAD`.quiet().nothrow()).stdout.toString().trim()) || 0;
    if (behind <= 0) continue;
    const why = await pluginDiverged(dir);
    console.error(
      why
        ? `${id} is ${behind} commit(s) behind its remote, and \`omarchy plugin update\` can't fast-forward it: ${dir} has ${why}; bring it up to date by hand`
        : `${id} is ${behind} commit(s) behind its remote: run \`omarchy plugin update ${id}\`, then this again`,
    );
  }
}

// ── Menu entries ───────────────────────────────────────────────────────────
// Entries of our own in the Omarchy menu (Keystroke serves it): a block in
// ~/.config/omarchy/extensions/omarchy-menu.jsonc, right after the object's
// opening brace, between marker comments named for the script. The entries
// end in commas; the menu's reader drops trailing ones.

export const MENU = `${HOME}/.config/omarchy/extensions/omarchy-menu.jsonc`;

const menuMarkers = (name: string) => [`  // >>> Managed by loadout (${name})`, `  // <<< Managed by loadout (${name})`];
const lines = (text: string) => text.replace(/\n+$/, "").split("\n");

/** The block as it should be: the markers, the note, entriesFile's lines. */
async function menuBlock(name: string, note: string, entriesFile: string) {
  const [begin, end] = menuMarkers(name);
  return [begin, `  // ${note}`, ...lines(await read(entriesFile)), end];
}

/** The menu's lines, split into name's block (markers included) and the rest. */
async function menuSplit(name: string) {
  const [begin, end] = menuMarkers(name);
  const block: string[] = [];
  const rest: string[] = [];
  let inside = false;
  for (const line of lines(await read(MENU))) {
    if (line === begin) inside = true;
    (inside ? block : rest).push(line);
    if (line === end) inside = false;
  }
  return { block, rest };
}

/** The block is in the menu as written. */
export async function menuBlockInPlace(name: string, note: string, entriesFile: string) {
  return (await menuSplit(name)).block.join("\n") === (await menuBlock(name, note, entriesFile)).join("\n");
}

/** (Re)writes the block, right after the first line that opens the object. */
export async function menuBlockWrite(name: string, note: string, entriesFile: string) {
  if (!(await Bun.file(MENU).exists())) await replaceFile(MENU, "{\n}\n");
  const { rest } = await menuSplit(name);
  const brace = rest.findIndex((l) => /^\s*\{/.test(l));
  if (brace < 0) throw new Error(`${MENU} has no opening brace to put the menu entries after`);
  const block = await menuBlock(name, note, entriesFile);
  await replaceFile(MENU, [...rest.slice(0, brace + 1), ...block, ...rest.slice(brace + 1)].join("\n") + "\n");
}

// ── Command overrides ──────────────────────────────────────────────────────
// Local replacements of Omarchy commands (see omarchy-command-overrides.ts).
// Everything Hyprland starts (the shell with its lock and idle code
// included) finds commands on a PATH that starts with OVERRIDES_DIR, ahead
// of Omarchy's own $OMARCHY_PATH/bin, so a wrapper there replaces the
// Omarchy command of the same name.

export const OVERRIDES_DIR = `${HOME}/.local/share/omarchy-overrides/bin`;
export const OMARCHY_BIN = `${process.env.OMARCHY_PATH || "/usr/share/omarchy"}/bin`;

/** The first command on the PATH path, or "". */
export function resolveOn(path: string, command: string): string {
  for (const dir of path.split(":")) {
    if (!dir) continue;
    try {
      accessSync(`${dir}/${command}`, constants.X_OK);
      return `${dir}/${command}`;
    } catch {}
  }
  return "";
}

/** The running Omarchy shell's PATH, or "" when it isn't running. */
export async function shellPath(): Promise<string> {
  const pid = (await $`pgrep -x quickshell`.quiet().nothrow()).stdout.toString().split("\n")[0].trim();
  if (!pid) return "";
  const environ = await read(`/proc/${pid}/environ`);
  return environ.split("\0").find((v) => v.startsWith("PATH="))?.slice(5) ?? "";
}

/** The session runs OVERRIDES_DIR/command for command: on the PATH the evaluated Hyprland config produces, and on the running shell's. */
export async function overrideActive(command: string): Promise<boolean> {
  const wrapper = `${OVERRIDES_DIR}/${command}`;
  if (resolveOn(await probe("env:PATH"), command) !== wrapper) return false;
  const live = await shellPath();
  return !live || resolveOn(live, command) === wrapper;
}

/** Writes an executable file (a wrapper, a hook handler). */
export async function writeExecutable(path: string, text: string) {
  await mkdir(dirname(path), { recursive: true });
  await Bun.write(path, text);
  await $`chmod 755 ${path}`.quiet();
}

/** path holds exactly text and is executable. */
export async function executableHolds(path: string, text: string): Promise<boolean> {
  try {
    accessSync(path, constants.X_OK);
  } catch {
    return false;
  }
  return (await read(path)) === text;
}
