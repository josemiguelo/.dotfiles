// What the Hyprland scripts share (Bun): asking hypr-option.lua what the Lua
// config ends up with, blocks of our own in Hyprland's personal files, and
// the running Hyprland.
import { readdirSync, statSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { $, read } from "#loadout";

const LIB = import.meta.dir;
export const HOME = process.env.HOME!;
export const BINDINGS = `${HOME}/.config/hypr/bindings.lua`;
/** Omarchy's defaults alone, for what Omarchy itself binds. */
export const OMARCHY_DEFAULTS = `${LIB}/hypr-omarchy-defaults.lua`;

/**
 * hypr-option.lua's answer for query ("bind:SUPER + Q", "action:<window.close>",
 * "rules:size", "leaves") over the whole config, or over config; throws, with
 * its reason, when the config can't be evaluated.
 */
export async function probe(query: string, config?: string): Promise<string> {
  const args = config ? [query, config] : [query];
  return (await $`lua ${LIB}/hypr-option.lua ${args}`.quiet().text()).trim();
}

/** "SUPER + Q" and "super+q" are the same key. */
export const sameKey = (a: string, b: string) => a.replace(/\s+/g, "").toUpperCase() === b.replace(/\s+/g, "").toUpperCase();

const markers = (name: string) => [`-- >>> Managed by loadout (${name})`, `-- <<< Managed by loadout (${name})`];

/** The block named name in file, markers included, as its lines; [] when there's none. */
export async function blockIn(file: string, name: string): Promise<string[]> {
  const [begin, end] = markers(name);
  const out: string[] = [];
  let keep = false;
  for (const line of (await read(file)).split("\n")) {
    if (line === begin) keep = true;
    if (keep) out.push(line);
    if (line === end) keep = false;
  }
  return out;
}

/** body between name's markers, as the block lines file should hold. */
export const block = (name: string, body: string[]) => {
  const [begin, end] = markers(name);
  return [begin, ...body, end];
};

/**
 * file with name's block replaced by body: the rest of the file, its trailing
 * blank lines dropped, a blank line, then the block at the end.
 */
export async function writeBlock(file: string, name: string, body: string[]) {
  const [begin, end] = markers(name);
  const rest: string[] = [];
  let skip = false;
  for (const line of (await read(file)).split("\n")) {
    if (line === begin) skip = true;
    if (!skip) rest.push(line);
    if (line === end) skip = false;
  }
  await mkdir(dirname(file), { recursive: true });
  await Bun.write(file, rest.join("\n").replace(/\n+$/, "") + "\n\n" + block(name, body).join("\n") + "\n");
}

/**
 * The running Hyprland's instance: the environment's, else the newest that
 * answers (a shell that outlived a re-login still names the dead one, and
 * hyprctl exits 0 even when it can't connect); null when none does.
 */
export async function liveInstance(): Promise<string | null> {
  const dir = join(process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid!()}`, "hypr");
  let found: string[] = [];
  try {
    found = readdirSync(dir).sort((a, b) => statSync(join(dir, b)).mtimeMs - statSync(join(dir, a)).mtimeMs);
  } catch {}
  const env = process.env.HYPRLAND_INSTANCE_SIGNATURE;
  for (const sig of env ? [env, ...found] : found) {
    const version = await $`hyprctl -j version`.env({ ...process.env, HYPRLAND_INSTANCE_SIGNATURE: sig }).quiet().nothrow();
    if (version.stdout.toString().includes('"branch"')) return sig;
  }
  return null;
}

/** hyprctl against instance sig. */
export const hyprctl = (sig: string, args: string[]) =>
  $`hyprctl ${args}`.env({ ...process.env, HYPRLAND_INSTANCE_SIGNATURE: sig }).quiet();

/** Reloads instance sig. */
export const reload = (sig: string) => hyprctl(sig, ["-q", "reload"]);

/** Fails with Hyprland's own errors when instance sig reports any. */
export async function noConfigErrors(sig: string) {
  const errors = (await hyprctl(sig, ["configerrors"]).text()).split("\n").filter((l) => l.trim()).join("\n");
  if (errors) throw new Error(`Hyprland reports config errors after the reload: ${errors}`);
}

export type Bind = { modmask: number; key: string; description: string };

/** Every binding of instance sig. */
export const binds = async (sig: string): Promise<Bind[]> => hyprctl(sig, ["binds", "-j"]).json();
