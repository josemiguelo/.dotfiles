#!/usr/bin/env bun
// Login shell for the current user: the zsh the package manager installed.
// usermod rather than chsh so it never prompts for a password (loadout runs
// this under captured output and asks for sudo itself).
// usage: default-shell.ts [check|install]; check: login shell already zsh?
import { $, fail, main, read } from "loadout/script";

const ZSH = Bun.which("zsh") ?? fail("zsh is not installed");
const USER = process.env.USER ?? fail("USER isn't set");
const darwin = process.platform === "darwin";

/** The user's login shell, from the directory service; "" when it can't say. */
async function currentShell() {
  if (darwin) {
    // "UserShell: /bin/zsh"
    const text = (await $`dscl . -read ${`/Users/${USER}`} UserShell`.quiet().nothrow()).stdout.toString();
    return text.split("\n")[0].trim().split(/\s+/)[1] ?? "";
  }
  const entry = (await $`getent passwd ${USER}`.quiet().nothrow()).stdout.toString().trim();
  return entry.split(":")[6] ?? "";
}

const ready = async () => (await currentShell()) === ZSH;

async function install() {
  if (!(await read("/etc/shells")).split("\n").includes(ZSH)) throw new Error(`${ZSH} is not listed in /etc/shells`);
  if (await ready()) return;
  if (darwin) await $`sudo chsh -s ${ZSH} ${USER}`;
  else await $`sudo usermod -s ${ZSH} ${USER}`;
  console.log(`login shell set to ${ZSH}; takes effect on next login`);
}

await main(ready, install);
