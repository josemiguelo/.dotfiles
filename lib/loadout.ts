// What loadout's Bun scripts share: the managed_by protocol, and commands as
// terse as sh's. Commands are Bun Shell's $`…`: each ${value} is one
// argument, quoted for you, and a command that fails throws, with its output.
import { realpathSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { basename, dirname, join } from "node:path";
import { $ } from "bun";
export { $ };

/** Is it on PATH? (sh's `command -v`) */
export const has = (program: string) => Bun.which(program) !== null;

/** Print to stderr and exit 1. */
export function fail(message: string): never {
  console.error(message);
  process.exit(1);
}

/** Its output, trimmed; throws when it fails. */
export const out = async (command: ReturnType<typeof $>) => (await command.quiet().text()).trim();

/** Did it succeed? Its output is discarded. */
export const ok = async (command: ReturnType<typeof $>) => (await command.quiet().nothrow()).exitCode === 0;

/**
 * A file's text, or "" when there's none. Node's readFile, not Bun.file: a
 * Bun.file that was stat'ed first reads only the size the stat gave, and
 * /proc files say 0.
 */
export const read = (path: string): Promise<string> => readFile(path, "utf8").catch(() => "");

/** Re-run test() until it's true; fails after tries * every seconds. */
export async function waitUntil(test: () => Promise<boolean>, what = "it", every = 10, tries = 360) {
  for (let i = 0; i < tries; i++) {
    if (await test()) return;
    await Bun.sleep(every * 1000);
  }
  fail(`${what} didn't happen in time`);
}

/**
 * file's path in its repo's main checkout, for a script that writes its own
 * path into a file outside the repo (an Omarchy hook, a command wrapper). Run
 * from a feature worktree, its own path dies with the worktree once the
 * feature merges, and the hook then fails silently on every call. The cost:
 * while a feature is tried, the hook runs master's copy of the script, not
 * the feature's (docs/worktrees.md, "Paths that outlive the worktree"). file
 * as an absolute path when it isn't in a worktree, or when the main checkout
 * has no copy yet (a script new to the feature): loadout's check, run from
 * the main checkout after the merge, sees the path differ and installs again.
 * lib/main-checkout.sh is the same, for sh scripts.
 */
export async function mainCheckoutPath(file: string): Promise<string> {
  const dir = realpathSync(dirname(file));
  const own = join(dir, basename(file));
  const top = await $`git -C ${dir} rev-parse --show-toplevel`.quiet().nothrow();
  const common = await $`git -C ${dir} rev-parse --path-format=absolute --git-common-dir`.quiet().nothrow();
  if (top.exitCode !== 0 || common.exitCode !== 0) return own;
  const commonDir = common.stdout.toString().trim();
  // A non-bare main checkout keeps the common git dir as its .git.
  if (basename(commonDir) !== ".git") return own;
  const main = dirname(commonDir) + own.slice(top.stdout.toString().trim().length);
  return (await Bun.file(main).exists()) ? main : own;
}

/** path in the repo loadout runs (`$LOADOUT_REPO`, which loadout sets for every command). */
export const repoPath = (path: string) => join(process.env.LOADOUT_REPO ?? fail("LOADOUT_REPO isn't set: run this through loadout"), path);

/**
 * Homebrew's prefix on this OS, from brew-prefix.sh, the one place that
 * decides it (the sh scripts source it). By OS, not by what exists: check for
 * `${prefix}/bin/brew` before relying on it.
 */
export const brewPrefix = () =>
  out($`sh -c ${'. "$1"; printf %s "$BREW_PREFIX"'} sh ${repoPath("loadouts/private_dot_local/lib/brew-prefix.sh")}`);

/** brew through brew.sh (a PATH brew first, then the prefix's; unattended), as every brew command the repo runs. */
export const brew = (...args: string[]) => $`sh ${repoPath("loadouts/private_dot_config/.homebrew/.loadout/brew.sh")} ${args}`;

type Step =(...args: string[]) => Promise<unknown> | unknown;

/**
 * The managed_by protocol: `check [args…]` exits 0 when it's done, 1 when not
 * (a check that throws isn't done, and says why); `[install] [args…]` does it,
 * and a failure exits 1 with its message.
 */
export async function main(check: (...args: string[]) => Promise<boolean> | boolean, install: Step) {
  const argv = Bun.argv.slice(2);
  const mode = argv[0] === "check" || argv[0] === "install" ? argv.shift() : "install";
  try {
    if (mode === "check") process.exit((await check(...argv)) ? 0 : 1);
    await install(...argv);
  } catch (error) {
    fail(reason(error));
  }
}

/**
 * A script with no check of its own (a manifest's `file`, its check inline):
 * runs step with the arguments, and a failure exits 1 with its message.
 */
export async function run(step: Step) {
  try {
    await step(...Bun.argv.slice(2));
  } catch (error) {
    fail(reason(error));
  }
}

/** What went wrong, as one line a user reads: a failed command's stderr. */
export function reason(error: unknown): string {
  if (error instanceof $.ShellError) {
    return error.stderr.toString().trim() || error.stdout.toString().trim() || `exited ${error.exitCode}`;
  }
  return error instanceof Error ? error.message : String(error);
}
