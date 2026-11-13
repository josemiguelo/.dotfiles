#!/usr/bin/env bun
// The keyboard backlight came back dark after sleep. Omarchy blanks through
// `omarchy-brightness-keyboard off` (the lock screen and the idle service),
// which saves the current level (brightnessctl -s) and sets 0; waking runs
// `restore`. But `off` saves every time, and blanking repeats while already
// dark (the lock screen re-blanks 5s after waking if untouched), so the second
// `off` saves 0 over the real level and waking restores 0.
//
// Until Omarchy fixes it, a wrapper skips `off` when the light is already 0
// and hands everything else to Omarchy's command. It goes in the directory
// omarchy-command-overrides puts first on the session's PATH (where the shell
// runs the lock and idle code), so the session runs it instead of Omarchy's.
//
// Whether Omarchy is still affected is decided by behavior, not text: its
// `off` runs against a stand-in brightnessctl that reports 0, and saving
// anyway means the wrapper is needed. Once it stops, install removes the
// wrapper. The check requires the session to actually run it (the evaluated
// config's PATH and the running shell's). Omarchy 4.5 fixed it: once every
// Omarchy machine has run install on 4.5 or later, this script can go.
// Modes: `check` / `install` (default).
import { existsSync, lstatSync, mkdtempSync } from "node:fs";
import { rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { $, main } from "loadout/script";
import { OMARCHY_BIN, OVERRIDES_DIR, executableHolds, overrideActive, writeExecutable } from "#omarchy";

const COMMAND = "omarchy-brightness-keyboard";
const OLD_WRAPPER = `/usr/local/bin/${COMMAND}`;
const WRAPPER = `${OVERRIDES_DIR}/${COMMAND}`;

const wrapper = `#!/bin/bash
# Managed by loadout (omarchy-keyboard-backlight-guard): skip \`off\` when the
# keyboard backlight is already dark, so a repeated blank doesn't save 0 over
# the level \`restore\` brings back after sleep. Everything else is Omarchy's.
direction=\${1:-up}
[[ \$direction == "--no-osd" ]] && direction=\${2:-up}

if [[ \$direction == "off" ]]; then
  for candidate in /sys/class/leds/*kbd_backlight*; do
    if [[ -e \$candidate ]]; then
      (( \$(brightnessctl -d "\$(basename "\$candidate")" get) == 0 )) && exit 0
      break
    fi
  done
fi

exec "${OMARCHY_BIN}/${COMMAND}" "\$@"
`;

/** Runs command's `off` against a stand-in brightnessctl whose light is at level: did it save (brightnessctl -s…)? */
async function savesWhen(command: string, level: number) {
  const tmp = mkdtempSync(`${tmpdir()}/backlight-guard.`);
  try {
    await writeExecutable(
      `${tmp}/brightnessctl`,
      `#!/bin/sh
case " $* " in
*" get "*) echo ${level} ;;
*" max "*) echo 100 ;;
esac
case "$1" in -s*) touch "${tmp}/saved" ;; esac
exit 0
`,
    );
    // Omarchy 4.5 on records the level in $XDG_RUNTIME_DIR instead: a stand-in
    // one, so the stub's 0 isn't what the next \`restore\` brings back.
    await $`${command} off`.env({ ...process.env, PATH: `${tmp}:${process.env.PATH}`, XDG_RUNTIME_DIR: tmp }).quiet().nothrow();
    return existsSync(`${tmp}/saved`);
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }
}

/** Omarchy's own command still saves over an already-dark light. */
const affected = () => savesWhen(`${OMARCHY_BIN}/${COMMAND}`, 0);

const guarded = async () => (await executableHolds(WRAPPER, wrapper)) && (await overrideActive(COMMAND));

const check = async () => ((await affected()) ? guarded() : !lstatSync(WRAPPER, { throwIfNoEntry: false }));

async function install() {
  if (await affected()) {
    await writeExecutable(WRAPPER, wrapper);
    if (!(await guarded())) throw new Error(`the session doesn't run ${WRAPPER}: is omarchy-command-overrides installed?`);
  } else {
    await rm(WRAPPER, { force: true });
    console.log(`Omarchy's ${COMMAND} no longer saves over a dark light: wrapper removed.`);
  }
  if (existsSync(OLD_WRAPPER)) {
    console.log(`An earlier attempt left ${OLD_WRAPPER} (unused: Omarchy's bin comes first). Remove it with: sudo rm ${OLD_WRAPPER}`);
  }
}

await main(check, install);
