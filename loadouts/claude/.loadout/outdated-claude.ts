// claude's own outdated check (../claude.loadout.ts): is the claude binary
// behind the latest published Claude Code release? claude.ai/install.sh
// installs it as a plain self-updating binary, so no package manager knows
// about it. `claude update` does the upgrade in place, so no re-install needed.
//
//   outdated-claude.ts          print the latest version when behind, else nothing
//   outdated-claude.ts update   install the latest release over the current binary
//
// Silent when claude isn't installed or the network is down -- and when the
// claude here isn't the native install: on Omarchy mise owns it (the dotfiles'
// mise config, updated by `omarchy update`), and ~/.local/bin/claude is
// Omarchy's wrapper script, not the binary, so `claude update` would fight
// mise. The native installer's layout is the tell: ~/.local/bin/claude is a
// symlink into ~/.local/share/claude/.
import { readlinkSync } from "node:fs";
import { $ } from "loadout/script";

const HOME = process.env.HOME!;
const NATIVE = `${HOME}/.local/bin/claude`;

/** The native install's version, "" when claude here isn't the native install. */
async function current() {
  let target = "";
  try {
    target = readlinkSync(NATIVE);
  } catch {}
  if (!target.startsWith(`${HOME}/.local/share/claude/`)) return "";
  const version = await $`${NATIVE} --version`.quiet().nothrow();
  return version.stdout
    .toString()
    .split("\n")
    .flatMap((line) => line.match(/^[0-9][0-9.]*/) ?? [])
    .join("\n");
}

/** The latest release, undefined offline. */
async function released() {
  const result = await $`curl -fsSL https://downloads.claude.ai/claude-code-releases/latest`.quiet().nothrow();
  return result.exitCode === 0 ? result.stdout.toString().replace(/\n+$/, "") : undefined;
}

export async function newerVersion() {
  const cur = await current();
  if (!cur) return undefined;
  const now = await released();
  return now !== cur ? now : undefined;
}

export async function update() {
  await $`${NATIVE} update`;
  console.log(`claude ${await current()}`);
}
