#!/usr/bin/env bun
// Kitty windows in the scratchpad (Hyper+Escape) less see-through than kitty's
// background_opacity, while every other kitty window keeps it. A Hyprland
// window rule can't do it: the compositor caps a window's opacity at 1, so a
// rule only makes windows more transparent — 1.12 and 3.0 looked the same
// as 1.0 on screen, tried live. Kitty has to repaint itself instead: a
// listener in ~/.config/hypr/hyprland.lua (where Omarchy puts personal
// additions) runs `kitten @ set-background-opacity` over the window's
// per-process socket (listen_on, from the dotfiles kitty.conf) when a kitty
// window moves into the scratchpad or opens there, and back to
// background_opacity when it moves out. Kitty only accepts that with
// dynamic_background_opacity on, which the dotfiles kitty.conf sets for this
// machine; kitty reads it at startup, so kitties already running stay put.
// The check compares the block's text: an event listener leaves nothing
// hypr-option.lua can list, unlike a window rule. The block is written from
// kitty.conf's background_opacity, so it drifts (and install rewrites it)
// when that changes. Install rewrites the block between its markers.
//
// Omarchy reloads every kitty's config (SIGUSR1) on a theme change
// (omarchy-restart-terminal), a font change (omarchy-font-set) and a text size
// change (omarchy-display-text-size), which puts scratchpad windows back at
// background_opacity. `reapply` sends the opacity again to the kitty windows in
// the scratchpad — now and a second later, since kitty finishes reloading on
// its own schedule — and runs from Omarchy's theme-set and font-set hooks
// (both run after the reload) and from a wrapper for omarchy-display-text-size
// in the directory omarchy-command-overrides puts first, since that one has no
// hook.
// usage: omarchy-scratchpad-opacity.ts [check|reapply] <opacity>
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { $, fail, mainCheckoutPath, main, ok, read } from "#loadout";
import { HOME, block, blockIn, hyprctl, liveInstance, noConfigErrors, reload, writeBlock } from "#hypr";
import { OMARCHY_BIN, OVERRIDES_DIR, overrideActive, executableHolds, writeExecutable } from "#omarchy";

const NAME = "omarchy-scratchpad-opacity";
const CONF = `${HOME}/.config/hypr/hyprland.lua`;
const KITTY = `${HOME}/.config/kitty/kitty.conf`;
const HOOKS = ["theme-set", "font-set"].map((h) => `${HOME}/.config/omarchy/hooks/${h}.d/scratchpad-opacity`);
const TEXT_SIZE = "omarchy-display-text-size";
const WRAPPER = `${OVERRIDES_DIR}/${TEXT_SIZE}`;
// The hooks and the wrapper run this script by its main checkout's path,
// which outlives a feature worktree this may be installed from.
const SELF = await mainCheckoutPath(import.meta.path);

function opacity(args: string[]) {
  if (args.length === 0) fail("usage: omarchy-scratchpad-opacity.ts [check|reapply] <opacity>");
  return args[0];
}

/** kitty.conf's last value for an option, or "". */
async function kittyOption(name: string) {
  let value = "";
  for (const line of (await read(KITTY)).split("\n")) {
    const [key, v] = line.trim().split(/\s+/);
    if (key === name && v) value = v;
  }
  return value;
}

/** kitty.conf's background_opacity, or kitty's own default when it's left out. */
const outside = async () => (await kittyOption("background_opacity")) || "1.0";

const dynamic = async () => (await kittyOption("dynamic_background_opacity")) === "yes";

const body = (inside: string, out: string) =>
  `-- Kitty windows in the scratchpad at ${inside} opacity, the rest at kitty.conf's
-- ${out}. Hyprland caps a window's opacity at 1, so kitty repaints itself
-- over its socket (loadouts/private_dot_config/.omarchy/.loadout/omarchy-scratchpad-opacity.ts).
local scratchpad_kitty_opacity = { inside = ${inside}, outside = ${out} }

local function set_kitty_opacity(window, opacity)
  if window.class ~= "kitty" then return end
  -- A window opened straight into the scratchpad may not be listening yet.
  local socket = os.getenv("XDG_RUNTIME_DIR") .. "/omarchy-kitty-" .. window.pid
  hl.exec_cmd(string.format(
    "for _ in $(seq 20); do [ -S %s ] && break; sleep 0.1; done; kitten @ --to unix:%s set-background-opacity %s",
    o.shell_quote(socket), o.shell_quote(socket), opacity
  ))
end

local function on_workspace(window, workspace)
  local inside = workspace and workspace.name == "special:scratchpad"
  set_kitty_opacity(window, inside and scratchpad_kitty_opacity.inside or scratchpad_kitty_opacity.outside)
end

hl.on("window.move_to_workspace", on_workspace)
hl.on("window.open", function(window)
  if window.workspace and window.workspace.name == "special:scratchpad" then on_workspace(window, window.workspace) end
end)`.split("\n");

const hook = (inside: string) => `# Managed by loadout (omarchy-scratchpad-opacity): Omarchy just reloaded every
# kitty's config, which puts scratchpad windows back at background_opacity.
bun '${SELF}' reapply ${inside}
`;

const wrapper = (inside: string) => `#!/bin/bash
# Managed by loadout (omarchy-scratchpad-opacity): after Omarchy's text size
# change reloads every kitty's config, send the scratchpad opacity again.
# Everything else is Omarchy's.
"${OMARCHY_BIN}/${TEXT_SIZE}" "$@"
status=$?
bun '${SELF}' reapply ${inside}
exit $status
`;

/** Sends the opacity to every kitty window in the scratchpad. */
async function sendToScratchpad(inside: string) {
  const sig = await liveInstance();
  if (!sig) return;
  const runtime = process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid!()}`;
  const clients: any[] = await hyprctl(sig, ["clients", "-j"]).json();
  for (const c of clients.filter((c) => c.class === "kitty" && c.workspace?.name === "special:scratchpad")) {
    const socket = `${runtime}/omarchy-kitty-${c.pid}`;
    if (existsSync(socket)) await ok($`kitten @ --to ${`unix:${socket}`} set-background-opacity ${inside}`);
  }
}

async function extrasReady(inside: string) {
  for (const h of HOOKS) if ((await read(h)) !== hook(inside)) return false;
  return (await executableHolds(WRAPPER, wrapper(inside))) && (await overrideActive(TEXT_SIZE));
}

async function check(...args: string[]) {
  const inside = opacity(args);
  return (
    (await dynamic()) &&
    (await blockIn(CONF, NAME)).join("\n") === block(NAME, body(inside, await outside())).join("\n") &&
    (await extrasReady(inside))
  );
}

async function install(...args: string[]) {
  const inside = opacity(args);
  if (!(await dynamic())) {
    throw new Error(`${KITTY} doesn't set dynamic_background_opacity yes (the dotfiles kitty.conf does, for this machine): apply the dotfiles first`);
  }
  await writeBlock(CONF, NAME, body(inside, await outside()));
  for (const h of HOOKS) {
    await mkdir(dirname(h), { recursive: true });
    await Bun.write(h, hook(inside));
  }
  await writeExecutable(WRAPPER, wrapper(inside));
  if (!(await extrasReady(inside))) throw new Error(`hooks or ${WRAPPER} not in place after install (is omarchy-command-overrides installed?)`);
  const sig = await liveInstance();
  if (!sig) return console.log("Hyprland isn't reachable from here; applies at the next login.");
  await reload(sig);
  await noConfigErrors(sig);
  console.log("Applies to kitty windows started from now on.");
}

const [mode, ...rest] = Bun.argv.slice(2);
if (mode === "reapply") {
  // Now, and a second later from a process of its own, so the hook that runs
  // this doesn't wait for it.
  const inside = opacity(rest);
  await sendToScratchpad(inside);
  spawn(process.execPath, [import.meta.path, "reapply-later", inside], { detached: true, stdio: "ignore" }).unref();
} else if (mode === "reapply-later") {
  await Bun.sleep(1000);
  await sendToScratchpad(opacity(rest)).catch(() => {});
} else {
  await main(check, install);
}
