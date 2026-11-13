#!/usr/bin/env bun
// ngrok v3 binary into ~/.local/bin. equinox ships tgz for linux and zip
// for macOS (the source recipe hardcoded linux-amd64).
// usage: install-ngrok.ts
import { chmod, mkdir, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { $, out, run } from "loadout/script";

const BIN_DIR = `${process.env.HOME}/.local/bin`;
const BASE = "https://bin.equinox.io/c/bNyj1mQVY4c";

/** Each platform's archive, by process.platform-process.arch. */
const FILES: Record<string, string> = {
  "linux-x64": "ngrok-v3-stable-linux-amd64.tgz",
  "linux-arm64": "ngrok-v3-stable-linux-arm64.tgz",
  "darwin-arm64": "ngrok-v3-stable-darwin-arm64.zip",
  "darwin-x64": "ngrok-v3-stable-darwin-amd64.zip",
};

async function install() {
  const file = FILES[`${process.platform}-${process.arch}`];
  if (!file) throw new Error(`unsupported platform: ${await out($`uname -s`)}/${await out($`uname -m`)}`);

  await mkdir(BIN_DIR, { recursive: true });
  // Downloaded whole first, failing on an HTTP error: an error page never
  // reaches tar or unzip. Equinox publishes no checksums for these files.
  const tmp = await mkdtemp(join(tmpdir(), "ngrok-"));
  try {
    const response = await fetch(`${BASE}/${file}`);
    if (!response.ok) throw new Error(`${BASE}/${file}: ${response.status} ${response.statusText}`);
    await Bun.write(`${tmp}/${file}`, response);
    if (file.endsWith(".tgz")) await $`tar -xzf ${`${tmp}/${file}`} -C ${BIN_DIR} ngrok`;
    else await $`unzip -o ${`${tmp}/${file}`} ngrok -d ${BIN_DIR}`;
    await chmod(`${BIN_DIR}/ngrok`, 0o755);
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }
}

await run(install);
