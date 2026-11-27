// What a script can't do without the user: a command they answer on this
// terminal, and waiting for something they do elsewhere.

/**
 * argv on this terminal, with this process's environment as it is now: a
 * Bun.spawn left to itself gets the environment the script started with, so
 * an SSH_AUTH_SOCK or PATH set since would be lost. Throws when it fails.
 */
export async function onTerminal(...argv: string[]) {
  const bin = Bun.which(argv[0], { PATH: process.env.PATH }) ?? argv[0];
  const code = await Bun.spawn([bin, ...argv.slice(1)], { env: process.env, stdio: ["inherit", "inherit", "inherit"] }).exited;
  if (code !== 0) throw new Error(`${argv.join(" ")} failed (exit ${code})`);
}

/**
 * tell prints what the user has to do, in yellow on a terminal: Bun prints
 * console.error in red, as if something had failed.
 */
export function tell(text: string) {
  const color = process.stderr.isTTY && !process.env.NO_COLOR;
  process.stderr.write(color ? `\x1b[33m${text}\x1b[0m\n` : `${text}\n`);
}

/** Seconds from an environment variable: its default when unset, empty or not a number (0 means don't wait). */
export function seconds(name: string, fallback: number) {
  const value = Number(process.env[name]);
  return process.env[name]?.trim() && Number.isFinite(value) && value >= 0 ? value : fallback;
}

/**
 * Polls done() every `every` seconds until it's true, after printing what the
 * user has to do and a countdown each minute; gives up after `wait` seconds
 * with an error saying so (who names the step).
 */
export async function waitForUser(
  who: string,
  done: () => Promise<boolean> | boolean,
  { wait, instructions, every = 3 }: { wait: number; instructions: string; every?: number },
) {
  if (await done()) return;
  tell(`\n==> ${instructions.replace("{wait}", `${Math.ceil(wait / 60)}m`)}`);
  const deadline = Date.now() + wait * 1000;
  let last = -1;
  while (!(await done())) {
    if (Date.now() >= deadline) throw new Error(`${who}: gave up waiting after ${wait}s; run this again once it's done`);
    const left = Math.ceil((deadline - Date.now()) / 60000);
    if (left !== last) {
      tell(`    still waiting (about ${left}m left)…`);
      last = left;
    }
    await Bun.sleep(every * 1000);
  }
}
