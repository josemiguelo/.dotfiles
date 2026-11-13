#!/usr/bin/env bun
// The battery stops charging at the limit the machine names:
// `args(script.t2-charge-limit, "85")`.
//
// t2smc puts the T2 SMC's charge limit (the key CHLS, what macOS's powerd
// sets) on BAT0 as charge_control_end_threshold, 1-100, 100 for none. The SMC
// keeps it across reboots and operating systems, so one write holds: no udev
// rule or boot unit. It also holds in macOS, whose battery management may set
// its own; the check then sees the drift.
//
// A permanent limit keeps the gauge from recalibrating, so something has to
// lift it for a full charge now and then: t2smc's battery_charge_limit_suspended
// (KaiT2en's t2-smc-gaugingd sets it, as powerd does on macOS). While it's
// set, the limit itself stays as it was; the check reads the limit, not the
// charge, so a calibration charge isn't drift.
// Modes: `check` / `install` (default).
import { readdirSync } from "node:fs";
import { $, main, readTrimmed } from "loadout/script";

const LIMIT = "/sys/class/power_supply/BAT0/charge_control_end_threshold";

/** The limit asked for, a whole number from 1 to 100. */
function wanted(arg: string | undefined) {
  const n = Number(arg);
  if (!Number.isInteger(n) || n < 1 || n > 100) throw new Error(`t2-charge-limit takes a limit from 1 to 100, not '${arg}'`);
  return String(n);
}

/** Whether a calibration charge has the limit lifted right now, for the message. */
async function suspended() {
  for (const hw of readdirSync("/sys/class/hwmon")) {
    if ((await readTrimmed(`/sys/class/hwmon/${hw}/name`)) === "t2smc") {
      return (await readTrimmed(`/sys/class/hwmon/${hw}/battery_charge_limit_suspended`)) === "1";
    }
  }
  return false;
}

async function ready(arg?: string) {
  return (await readTrimmed(LIMIT)) === wanted(arg);
}

async function install(arg?: string) {
  const limit = wanted(arg);
  if (!(await readTrimmed(LIMIT))) throw new Error(`${LIMIT} isn't there: is t2smc loaded?`);
  if (await ready(limit)) return;
  // In place: a sysfs attribute can't be replaced the way sudoWrite does (install).
  await $`sudo sh -c ${'echo "$1" > "$2"'} sh ${limit} ${LIMIT}`;
  if (!(await ready(limit))) throw new Error(`the SMC didn't take a charge limit of ${limit}`);
  if (await suspended()) console.log(`The limit is ${limit}%, lifted for now by a calibration charge (battery_charge_limit_suspended).`);
}

await main(ready, install);
