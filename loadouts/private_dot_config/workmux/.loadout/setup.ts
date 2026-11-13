#!/usr/bin/env bun
// workmux's status-tracking hooks and bundled skills, for every agent whose
// config folder is here: what `workmux setup --hooks --skills` writes.
// workmux can't report it, so check looks for the files it writes, the way it
// finds agents (by config folder), and for a stamp of the workmux version it
// last ran with: an upgrade can change the hooks or skills, so it reruns once.
// A new agent or skill in workmux needs a line here.
// setup asks before each part and only on a terminal, so install runs it in
// one (script) and answers yes.
// It also runs `opencode --version` (to pick OpenCode's plugin), and Omarchy's
// opencode is a lazy mise tool that installs on its first run: on a fresh
// machine that install failed inside setup, which only says "opencode
// --version failed" and fails the whole step. So install runs it once first,
// its errors on screen: OpenCode installs on its own, or the run says why not.
// Modes: `check` / `install` (default).
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { $, main, out, read } from "loadout/script";
import { brewPrefix } from "#brew";

const HOME = process.env.HOME!;
// brew's bin: workmux comes from a brew tap, and a new machine's shell
// hasn't run `brew shellenv` yet.
const PATH = `${await brewPrefix()}/bin:${process.env.PATH}`;
const env = { ...process.env, PATH };

const SKILLS = ["merge", "rebase", "worktree", "coordinator", "open-pr", "workmux"];
const STAMP = `${process.env.XDG_STATE_HOME || `${HOME}/.local/state`}/workmux-setup/version`;
const CLAUDE = process.env.CLAUDE_CONFIG_DIR || `${HOME}/.claude`;
const PI = `${HOME}/.pi/agent`;
const CODEX = `${HOME}/.codex`;
const COPILOT = process.env.COPILOT_CONFIG_DIR || `${HOME}/.copilot`;
const OPENCODE = process.env.OPENCODE_CONFIG_DIR || `${process.env.XDG_CONFIG_HOME || `${HOME}/.config`}/opencode`;

const has = async (text: string, file: string) => (await read(file)).includes(text);
const skillsMissing = (dir: string) => SKILLS.filter((s) => !existsSync(`${dir}/${s}/SKILL.md`)).map((s) => `missing skill: ${dir}/${s}`);
const workmuxVersion = () => out($`workmux --version`.env(env));

/** What's missing, one line each. */
async function missing() {
  const gaps: string[] = [];
  if (existsSync(CLAUDE)) {
    if (!(await has("workmux set-window-status", `${CLAUDE}/settings.json`))) gaps.push(`missing hooks: ${CLAUDE}/settings.json`);
    gaps.push(...skillsMissing(`${CLAUDE}/skills`));
  }
  if (existsSync(PI)) {
    if (!existsSync(`${PI}/extensions/workmux-status.ts`)) gaps.push(`missing hooks: ${PI}/extensions/workmux-status.ts`);
    gaps.push(...skillsMissing(`${PI}/skills`));
  }
  if (existsSync(CODEX) && !(await has("workmux set-window-status", `${CODEX}/hooks.json`))) {
    gaps.push(`missing hooks: ${CODEX}/hooks.json`);
  }
  if (existsSync(COPILOT) && !existsSync(`${COPILOT}/hooks/workmux-status.json`)) {
    gaps.push(`missing hooks: ${COPILOT}/hooks/workmux-status.json`);
  }
  if (existsSync(OPENCODE)) {
    // Older workmux wrote plugin/workmux-status.ts, newer plugins/workmux-status/:
    // either will do.
    if (!existsSync(`${OPENCODE}/plugin/workmux-status.ts`) && !existsSync(`${OPENCODE}/plugins/workmux-status`)) {
      gaps.push(`missing hooks: ${OPENCODE}/plugins/workmux-status`);
    }
    gaps.push(...skillsMissing(`${OPENCODE}/skills`));
  }
  const version = await workmuxVersion();
  if ((await read(STAMP)).trim() !== version) gaps.push(`last set up by another workmux than ${version}`);
  return gaps;
}

/** `workmux setup` asks before each part and only on a terminal: run in one (script), every question answered yes. */
async function setupInTerminal() {
  const command = "workmux setup --hooks --skills";
  const argv = process.platform === "darwin" ? ["script", "-q", "/dev/null", "sh", "-c", command] : ["script", "-q", "-e", "-c", command, "/dev/null"];
  const proc = Bun.spawn(argv, { env, stdin: "pipe", stdout: "inherit", stderr: "inherit" });
  proc.stdin.write("y\n".repeat(10));
  proc.stdin.end();
  const code = await proc.exited;
  if (code !== 0) throw new Error(`workmux setup failed (exit ${code})`);
}

const ready = async () => (await missing()).length === 0;

async function install() {
  if (Bun.which("opencode", { PATH })) {
    console.error("workmux-setup: OpenCode first (Omarchy installs it on first use)");
    const code = await Bun.spawn(["opencode", "--version"], { env, stdout: "ignore", stderr: "inherit" }).exited;
    if (code !== 0) throw new Error("opencode --version failed: workmux setup can't pick its plugin");
  }
  await setupInTerminal();
  mkdirSync(dirname(STAMP), { recursive: true });
  writeFileSync(STAMP, `${await workmuxVersion()}\n`);
  const left = await missing();
  if (left.length > 0) throw new Error(`workmux setup left these out:\n${left.join("\n")}`);
}

await main(ready, install);
