#!/usr/bin/env bun
// After every `omarchy update`, check the T2 Mac's setup and say when the
// update undid part of it.
//
// Upstream Omarchy doesn't know this machine's T2 stack: a migration can
// rewrite the kernel arguments or the initramfs modules, `omarchy refresh
// pacman` the repo, the orphan cleanup a package. loadout notices, but only
// when it's asked. Omarchy runs ~/.config/omarchy/hooks/post-update.d/* after
// each update, so a hook there asks it: `loadout status` for the T2 items (the
// t2-* and kait2en programs and scripts, bankstown, the APFS driver, the
// remove-t2-* steps), and a critical notification naming any not installed or
// not done, which `loadout run <name>` (or `loadout install`) repairs. The
// status takes a few seconds and writes nothing.
// Modes: `check` / `install` (default).
import { chmodSync, existsSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { main, readTrimmed } from "#loadout";

const HOOK = `${process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`}/omarchy/hooks/post-update.d/t2-loadout-check`;

const HOOK_TEXT = `#!/bin/bash
# Managed by loadout (t2-post-update-check): after \`omarchy update\`, check the T2
# Mac's setup with loadout and say which items the update undid
# (loadouts/.etc/t2/.loadout/post-update-check.ts).
loadout=$(command -v loadout || echo "$HOME/.local/bin/loadout")
[[ -x $loadout ]] || exit 0
json=$("$loadout" --repo "\${LOADOUT_REPO:-$HOME/.local/share/chezmoi}" status --json --no-write 2>/dev/null) || exit 0
pending=$(jq -r '
  [(.programs | to_entries[] | select(.value.status != "installed")),
   (.scripts | to_entries[] | select(.value.status != "done"))]
  | map(select(.key | test("^(t2|kait2en|remove-t2|bankstown|linux-apfs)"))) | .[].key' <<<"$json" | tr '\\n' ' ')
[[ -n \${pending// } ]] || exit 0
echo "T2 setup: not in place after the update: $pending(loadout run <name>, or loadout install <name>)"
notify-send -u critical -a loadout "T2 setup needs attention after the update" \\
  "Not in place: $pending— loadout run <name> (scripts) or loadout install <name> (packages)"
exit 0
`;

const ready = async () => existsSync(HOOK) && (await readTrimmed(HOOK)) === HOOK_TEXT.replace(/\n+$/, "");

async function install() {
  mkdirSync(dirname(HOOK), { recursive: true });
  await Bun.write(HOOK, HOOK_TEXT);
  chmodSync(HOOK, 0o755);
  if (!(await ready())) throw new Error(`${HOOK} not in place after install`);
}

await main(ready, install);
