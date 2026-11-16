#!/usr/bin/env bun
// The battery stops charging at the limit the machine names:
// `args(script.t2-charge-limit, "85")`.
//
// t2smc puts the T2 SMC's charge limit (the key CHLS, what macOS's powerd
// sets) on BAT0 as charge_control_end_threshold, 1-100, 100 for none. The SMC
// keeps it across reboots and operating systems, so one write mostly holds.
// But macOS's battery management sets its own: a macOS session on 2026-11-16
// left it at 100 (none). So a boot unit, t2-charge-limit.service, writes the
// limit again at every boot, waiting for t2smc's attribute (it appears when
// t2smc binds, after early boot). The check wants the limit and the unit.
//
// A permanent limit keeps the gauge from recalibrating, so something has to
// lift it for a full charge now and then: t2smc's battery_charge_limit_suspended
// (KaiT2en's t2-smc-gaugingd sets it, as powerd does on macOS). While it's
// set, the limit itself stays as it was; the check reads the limit, not the
// charge, so a calibration charge isn't drift.
// Modes: `check` / `install` (default).
import { readdirSync } from "node:fs";
import { $, main, ok, readTrimmed, sudoWrite } from "loadout/script";

const LIMIT = "/sys/class/power_supply/BAT0/charge_control_end_threshold";
const SERVICE = "t2-charge-limit.service";
const UNIT = `/etc/systemd/system/${SERVICE}`;

/** The boot unit for a limit: wait up to 60 s for t2smc's attribute, then write it. */
const unitText = (limit: string) => `# Managed by loadout (t2-charge-limit): the battery charge limit, written again
# at every boot. The T2 SMC keeps it, but macOS's battery management may change
# it. t2-smc-gaugingd's calibration charges lift it separately (suspended), not
# by changing it.
[Unit]
Description=T2 battery charge limit (${limit}%)
After=systemd-modules-load.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for i in $$(seq 60); do [ -w ${LIMIT} ] && break; sleep 1; done; echo ${limit} > ${LIMIT}'

[Install]
WantedBy=multi-user.target
`;

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
  return (await readTrimmed(UNIT)) === unitText(limit).replace(/\n+$/, "") &&
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
  if (!(await unitReady(limit))) {
    await sudoWrite(UNIT, unitText(limit));
    await $`sudo systemctl daemon-reload`;
    await $`sudo systemctl enable ${SERVICE}`;
  }
  // Now too, in place: a sysfs attribute can't be replaced the way sudoWrite does (install).
  if (!(await limitSet(limit))) await $`sudo sh -c ${'echo "$1" > "$2"'} sh ${limit} ${LIMIT}`;
  if (!(await limitSet(limit))) throw new Error(`the SMC didn't take a charge limit of ${limit}`);
  if (!(await unitReady(limit))) throw new Error(`${UNIT} isn't in place and enabled after install`);
  if (await suspended()) console.log(`The limit is ${limit}%, lifted for now by a calibration charge (battery_charge_limit_suspended).`);
}

await main(ready, install);
