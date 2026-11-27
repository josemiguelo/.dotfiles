// omarchy-theme-set-tmux runs on every `omarchy theme set` and pushes the
// omarchy theme's colours into the live tmux server: window-style,
// window-active-style and cursor-colour globally, plus OSC 10/11/4 (fg, bg,
// palette) into every pane alive at the time. tmux here follows kitty's own
// palette instead, so afterwards pane content stops matching the status line
// and kitty's tabs, goes opaque (an explicit bg defeats background_opacity),
// and panes opened later disagree with older ones. The dotfiles pin the
// globals for a reload; a running server is reset here, and — because every
// later theme switch repaints it again — by an Omarchy theme-set hook this
// installs: omarchy-theme-set runs ~/.config/omarchy/hooks/theme-set.d/*
// (with bash) after omarchy-theme-set-tmux has finished, and the hook calls
// `reset`.
// check: the hook in place and the server untouched. install: the hook, and a
// reset. Run as a file with `reset`, it resets the server only: what the hook runs.
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { $, fail, mainCheckoutPath, succeeds, outputOf, read, reason } from "loadout/script";

const HOOK = `${process.env.HOME}/.config/omarchy/hooks/theme-set.d/tmux-follows-kitty`;

/**
 * The hook runs this script by its main checkout's path, which outlives a
 * feature worktree this may be installed from, through `loadout bun`:
 * "loadout/script" is a module inside loadout, so a plain bun can't run it.
 * It runs without LOADOUT_REPO.
 */
const hookBody = async () => `# Managed by loadout (omarchy-tmux-theme): undo omarchy-theme-set-tmux's
# window-style/cursor/pane colours so tmux keeps kitty's palette and
# background_opacity. Runs after every theme switch.
loadout bun '${await mainCheckoutPath(import.meta.path)}' reset`;

const hookCurrent = async () => (await read(HOOK)) === (await hookBody());
const tmuxRunning = () => succeeds($`tmux list-sessions`);

async function globalsClean() {
  const show = (option: string) => outputOf($`tmux show -gv ${option}`);
  // Unset reads as none before tmux 3.8 and as nothing from 3.8 on.
  return (
    (await show("window-style")) === "default" &&
    (await show("window-active-style")) === "default" &&
    ["", "none"].includes(await show("cursor-colour"))
  );
}

const panesClean = async () =>
  (await outputOf($`tmux list-panes -a -F ${"#{pane_bg} #{pane_fg}"}`)).split("\n").every((l) => l === "default default");

async function reset() {
  if (!(await tmuxRunning())) return;
  await $`tmux set -g window-style default`;
  await $`tmux set -g window-active-style default`;
  await $`tmux set -gu cursor-colour`;
  // OSC 110/111/104 hand a pane's fg, bg and palette back to the terminal.
  for (const tty of new Set((await outputOf($`tmux list-panes -a -F ${"#{pane_tty}"}`)).split("\n").filter(Boolean))) {
    try {
      writeFileSync(tty, "\x1b]110\x07\x1b]111\x07\x1b]104\x07");
    } catch {
      // A pane that went away meanwhile.
    }
  }
  for (const client of (await outputOf($`tmux list-clients -F ${"#{client_name}"}`)).split("\n").filter(Boolean)) {
    await $`tmux refresh-client -t ${client}`.quiet().nothrow();
  }
}

export const check = async () => (await hookCurrent()) && (!(await tmuxRunning()) || ((await globalsClean()) && (await panesClean())));

export async function install() {
  mkdirSync(dirname(HOOK), { recursive: true });
  writeFileSync(HOOK, await hookBody());
  await reset();
}

// What the hook runs.
if (import.meta.main) {
  if (Bun.argv[2] !== "reset") fail("usage: omarchy-theme.ts reset");
  await reset().catch((error) => fail(reason(error)));
}
