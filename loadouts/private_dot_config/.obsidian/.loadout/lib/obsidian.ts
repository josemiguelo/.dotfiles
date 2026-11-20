// Obsidian for obsidian-vault and obsidian-copilot: the vault from an
// argument, whether the app runs, starting it, and waiting on the user (the
// way onepassword-cli does) for what a script can't do.
import { readdirSync, readFileSync } from "node:fs";

/** A vault argument as a path: ~ and $HOME expanded, no trailing slash. */
export const vaultPath = (vault: string) => vault.replace(/^(~|\$HOME)(?=\/|$)/, process.env.HOME!).replace(/\/+$/, "");

/** Seconds from an environment variable: its default when unset, empty or not a number (0 means don't wait). */
export function seconds(name: string, fallback: number) {
  const value = Number(process.env[name]);
  return process.env[name]?.trim() && Number.isFinite(value) && value >= 0 ? value : fallback;
}

/**
 * Is Obsidian running? Arch's runs as electron with /usr/lib/obsidian/app.asar
 * as an argument (no process is named obsidian). Read from /proc, argument by
 * argument: `pgrep -f obsidian/app.asar` also matches any shell whose command
 * line merely mentions it.
 */
export function obsidianRunning() {
  for (const pid of readdirSync("/proc")) {
    if (!/^\d+$/.test(pid)) continue;
    let argv: string[];
    try {
      argv = readFileSync(`/proc/${pid}/cmdline`, "utf8").split("\0");
    } catch {
      continue;
    }
    if (/(^|\/)electron\d*$/.test(argv[0] ?? "") && argv.includes("/usr/lib/obsidian/app.asar")) return true;
  }
  return false;
}

/** Obsidian, started detached through uwsm like the launcher does, unless it runs or there's no display. */
export function openObsidian() {
  if (!Bun.which("obsidian") || obsidianRunning()) return;
  if (!process.env.WAYLAND_DISPLAY && !process.env.DISPLAY) return;
  const argv = Bun.which("uwsm-app") ? ["setsid", "uwsm-app", "--", "obsidian"] : ["setsid", "obsidian"];
  Bun.spawn(argv, { stdio: ["ignore", "ignore", "ignore"] }).unref();
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
  console.error(`\n==> ${instructions.replace("{wait}", `${Math.ceil(wait / 60)}m`)}`);
  const deadline = Date.now() + wait * 1000;
  let last = -1;
  while (!(await done())) {
    if (Date.now() >= deadline) throw new Error(`${who}: gave up waiting after ${wait}s; run this again once it's done`);
    const left = Math.ceil((deadline - Date.now()) / 60000);
    if (left !== last) {
      console.error(`    still waiting (about ${left}m left)…`);
      last = left;
    }
    await Bun.sleep(every * 1000);
  }
}
