#!/usr/bin/env bun
// Omarchy's keyboard-backlight keys reach UPower on the T2 Mac.
//
// Omarchy sets the keyboard backlight with `omarchy-brightness-keyboard`,
// which writes the LED through brightnessctl. t2hid's `:white:kbd_backlight`
// has no brightness_hw_changed, so UPower never hears of it: its level goes
// stale and it sends no BrightnessChanged. Two things here go by UPower: the
// idle fade (t2-kbd-backlight) fades back to UPower's level, and the Touch Bar
// matches its glyphs to the keys on UPower's signal. So a key change was lost
// to the fade and reached the bar only at its next wake.
//
// A wrapper in the directory omarchy-command-overrides puts first on the
// session's PATH runs Omarchy's command, then hands UPower the LED's new level
// (KbdBacklight.SetBrightness, which the session user may call): the same
// value, so nothing changes on the keyboard, but UPower's copy is right and
// it signals the change.
// Modes: `check` / `install` (default).
import { $, main } from "loadout/script";
import { OMARCHY_BIN, OVERRIDES_DIR, executableHolds, overrideActive, writeExecutable } from "#omarchy";

const COMMAND = "omarchy-brightness-keyboard";
const WRAPPER = `${OVERRIDES_DIR}/${COMMAND}`;

const wrapper = `#!/bin/bash
# Managed by loadout (t2-kbd-backlight-sync): run Omarchy's command, then tell
# UPower the keyboard backlight's new level, which brightnessctl's write doesn't
# (no brightness_hw_changed on the T2's LED), so t2-kbd-backlight's fade and
# the Touch Bar's glyphs follow the keys.
"${OMARCHY_BIN}/${COMMAND}" "$@"
status=$?
for candidate in /sys/class/leds/*kbd_backlight*; do
  if [[ -r $candidate/brightness ]]; then
    busctl call --quiet org.freedesktop.UPower /org/freedesktop/UPower/KbdBacklight \\
      org.freedesktop.UPower.KbdBacklight SetBrightness i "$(<"$candidate/brightness")" 2>/dev/null
    break
  fi
done
exit $status
`;

const ready = async () => (await executableHolds(WRAPPER, wrapper)) && (await overrideActive(COMMAND));

async function install() {
  if ((await $`busctl introspect org.freedesktop.UPower /org/freedesktop/UPower/KbdBacklight`.quiet().nothrow()).exitCode !== 0) {
    throw new Error("UPower has no KbdBacklight: is upower running?");
  }
  await writeExecutable(WRAPPER, wrapper);
  if (!(await ready())) throw new Error(`the session doesn't run ${WRAPPER}: is omarchy-command-overrides installed?`);
}

await main(ready, install);
