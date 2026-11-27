// Obsidian for obsidian-vault and obsidian-copilot: the vault from an
// argument, whether the app runs, starting it, and waiting on the user (the
// way onepassword-signin does) for what a script can't do.
import { readdirSync, readFileSync } from "node:fs";

export { seconds, waitForUser } from "#user";

/** A vault argument as a path: ~ and $HOME expanded, no trailing slash. */
export const vaultPath = (vault: string) => vault.replace(/^(~|\$HOME)(?=\/|$)/, process.env.HOME!).replace(/\/+$/, "");

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
