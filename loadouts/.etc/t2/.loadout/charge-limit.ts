#!/usr/bin/env bun
// The battery stops charging at the limit the machine names:
// `args(script.t2-charge-limit, "90")`. The T2 SMC stops 5 points below it
// and resumes once the battery drops further (tested 2026-11-16 on the
// MacBookPro16,1: limit 85 stopped at 80 %, limit 90 at 85 %), so name the
// limit 5 above the level you want; the check compares the limit, not the level.
//
// t2smc puts the T2 SMC's charge limit (the key CHLS, what macOS's powerd
// sets) on BAT0 as charge_control_end_threshold, 1-100, 100 for none. The SMC
// keeps it across reboots and operating systems, but macOS's battery
// management sets its own, so t2-smc-control's t2-charge-limit.service writes
// it again at every boot, from /etc/t2-charge-limit.conf (LIMIT=<n>). This is
// only the setting: that file, the unit enabled, and the limit now. (Before
// t2-smc-control 0.1.0.r34-2 the unit was this script's own, in
// /etc/systemd/system; install removes that copy.)
//
// A permanent limit keeps the gauge from recalibrating: t2-smc-gaugingd lifts
// it for a full charge now and then (t2smc's battery_charge_limit_suspended).
// While it's set the limit stays as it was; the check reads the limit, not the
// charge, so a calibration charge isn't drift.
// Modes: `check` / `install` (default).
import { existsSync, readdirSync } from "node:fs";
import { $, main, ok, readTrimmed, sudoWrite } from "loadout/script";

const LIMIT = "/sys/class/power_supply/BAT0/charge_control_end_threshold";
const SERVICE = "t2-charge-limit.service";
const CONF = "/etc/t2-charge-limit.conf";
// Where this script used to write the unit itself (now t2-smc-control's).
const OLD_UNIT = `/etc/systemd/system/${SERVICE}`;
const confText = (limit: string) => `# The battery charge limit t2-charge-limit.service writes at every boot (the\n# owner's dotfiles: t2-charge-limit). The SMC stops charging 5 points below it.\nLIMIT=${limit}\n`;

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

async function limitSet(limit: string) {
  return (await readTrimmed(LIMIT)) === limit;
}

async function unitReady(limit: string) {
  return !existsSync(OLD_UNIT) && existsSync(`/usr/lib/systemd/system/${SERVICE}`) &&
    (await readTrimmed(CONF)) === confText(limit).replace(/\n+$/, "") &&
    (await ok($`systemctl -q is-enabled ${SERVICE}`));
}

async function ready(arg?: string) {
  const limit = wanted(arg);
  return (await limitSet(limit)) && (await unitReady(limit));
}

async function install(arg?: string) {
  const limit = wanted(arg);
  if (!(await readTrimmed(LIMIT))) throw new Error(`${LIMIT} isn't there: is t2smc loaded?`);
  if (await ready(limit)) return;
  if (!existsSync(`/usr/lib/systemd/system/${SERVICE}`)) throw new Error(`${SERVICE} isn't installed: t2-smc-control 0.1.0.r34-2 or later ships it`);
  if (!(await unitReady(limit))) {
    if (existsSync(OLD_UNIT)) await $`sudo rm -f ${OLD_UNIT}`;
    await sudoWrite(CONF, confText(limit));
    await $`sudo systemctl daemon-reload`;
    await $`sudo systemctl enable ${SERVICE}`;
  }
  // Now too, in place: a sysfs attribute can't be replaced the way sudoWrite does (install).
  if (!(await limitSet(limit))) await $`sudo sh -c ${'echo "$1" > "$2"'} sh ${limit} ${LIMIT}`;
  if (!(await limitSet(limit))) throw new Error(`the SMC didn't take a charge limit of ${limit}`);
  if (!(await unitReady(limit))) throw new Error(`${CONF} and ${SERVICE} aren't in place and enabled after install`);
  if (await suspended()) console.log(`The limit is ${limit}%, lifted for now by a calibration charge (battery_charge_limit_suspended).`);
}

await main(ready, install);
