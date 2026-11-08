// What loadout's Bun scripts share: the managed_by protocol, and commands as
// terse as sh's. Commands are Bun Shell's $`…`: each ${value} is one
// argument, quoted for you, and a command that fails throws, with its output.
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

/** A file's text, or "" when there's none. */
export async function read(path: string): Promise<string> {
  const file = Bun.file(path);
  return (await file.exists()) ? file.text() : "";
}

/** Re-run test() until it's true; fails after tries * every seconds. */
export async function waitUntil(test: () => Promise<boolean>, what = "it", every = 10, tries = 360) {
  for (let i = 0; i < tries; i++) {
    if (await test()) return;
    await Bun.sleep(every * 1000);
  }
  fail(`${what} didn't happen in time`);
}

type Step = (...args: string[]) => Promise<unknown> | unknown;

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

/** What went wrong, as one line a user reads: a failed command's stderr. */
export function reason(error: unknown): string {
  if (error instanceof $.ShellError) {
    return error.stderr.toString().trim() || error.stdout.toString().trim() || `exited ${error.exitCode}`;
  }
  return error instanceof Error ? error.message : String(error);
}
