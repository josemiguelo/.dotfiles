// The 1Password CLI for the steps that read secrets with `op`
// (onepassword-cli, intentional-sync, kait2en-dev, t2-bcm-firmware).
import { $ } from "loadout/script";

const has = (program: string) => Bun.which(program) !== null;

/** A command's exit code, killed after seconds; its output kept quiet unless loud. */
async function exitOf(argv: string[], seconds: number, loud = false) {
  const proc = Bun.spawn(argv, {
    stdin: "ignore",
    stdout: "ignore",
    stderr: loud ? "inherit" : "ignore",
    timeout: seconds * 1000,
  });
  return proc.exited;
}

/**
 * The CLI reaches an account through the desktop app. It asks only for the
 * accounts list, which needs no approval prompt: the integration is set up,
 * not the app unlocked right now.
 */
export async function opConnected() {
  if (!has("op")) return false;
  const accounts = await $`op account list --format=json`.quiet().nothrow();
  try {
    return accounts.exitCode === 0 && JSON.parse(accounts.stdout.toString()).length > 0;
  } catch {
    return false;
  }
}

/**
 * The CLI lets this script read, asking in the open when it has to. A locked
 * app, or a CLI not yet approved this session, makes `op` wait on a prompt in
 * the 1Password app; with its output thrown away, that wait looked like a
 * hang. So: a quick silent try first (already approved: nothing shown), then
 * the wait announced, op's own messages on screen, for up to OP_UNLOCK_WAIT
 * seconds (default 120). who names the step in what it prints.
 */
export async function opUnlocked(who: string) {
  if ((await exitOf(["op", "vault", "list"], 5)) === 0) return;
  const wait = Number(process.env.OP_UNLOCK_WAIT || 120);
  console.error(`${who}: waiting for 1Password: unlock the app and approve its prompt…`);
  if ((await exitOf(["op", "vault", "list"], wait, true)) === 0) return;
  throw new Error(
    `${who}: 1Password didn't let the CLI in (still locked, the prompt was denied, or no answer in ${wait}s); run this again once it's unlocked`,
  );
}

/** A secret by its op:// reference: one read each, so a failed one stops there. */
export const opRead = async (ref: string) => (await $`op read ${ref}`.quiet().text()).trim();
