#!/usr/bin/env bun
// Intentional's ~/.config/intentional/sync.json, written from the "Intentional
// sync" item in 1Password (Personal vault): the Firebase database and API key,
// the one account every device signs in as, and the encryption key, plus this
// machine's device name (from the machine's run list), which must stay the
// same once the machine has synced. The file is readable by the user alone;
// writing it restarts the daemon, which reads it at start. `check` only reads
// the file, so it never asks 1Password anything.
// usage: sync-config.ts [check] <device name>
import { mkdirSync, renameSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { $, main, read } from "#loadout";
import { opRead, opUnlocked } from "#onepassword";

const CONFIG = `${process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`}/intentional/sync.json`;
const ITEM = "op://Personal/Intentional sync";
const FIELDS = ["databaseUrl", "apiKey", "email", "password", "key"] as const;

async function ready(device?: string) {
  if (!device) throw new Error("usage: sync-config.ts [check] <device name>");
  try {
    const sync = JSON.parse(await read(CONFIG));
    return sync.device === device && FIELDS.every((f) => typeof sync[f] === "string" && sync[f].length > 0);
  } catch {
    return false;
  }
}

async function install(device?: string) {
  if (await ready(device)) return;
  // onepassword-cli checks the integration is set up; reading also needs the
  // app unlocked, which only shows now.
  await opUnlocked("intentional-sync");
  // One read at a time, so a failed one stops here, and nothing is written
  // unless all came back.
  const sync = {
    databaseUrl: await opRead(`${ITEM}/database url`),
    apiKey: await opRead(`${ITEM}/api key`),
    email: await opRead(`${ITEM}/username`),
    password: await opRead(`${ITEM}/password`),
    key: await opRead(`${ITEM}/encryption key`),
    device,
  };
  if (FIELDS.some((f) => !sync[f])) throw new Error('1Password returned an empty field in "Intentional sync"');
  mkdirSync(dirname(CONFIG), { recursive: true, mode: 0o700 });
  writeFileSync(`${CONFIG}.tmp`, `${JSON.stringify(sync, null, 2)}\n`, { mode: 0o600 });
  renameSync(`${CONFIG}.tmp`, CONFIG);
  if (!(await ready(device))) throw new Error(`wrote ${CONFIG} but it doesn't pass the check`);
  await $`systemctl --user try-restart intentional.service`.quiet().nothrow();
  console.error(`Intentional syncs as "${device}"`);
}

await main(ready, install);
