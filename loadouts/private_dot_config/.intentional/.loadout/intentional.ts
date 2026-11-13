#!/usr/bin/env bun
// Intentional's desktop guard from its latest GitHub release
// (github.com/josemiguelo/intentional): the archive is checked against its
// SHA-256 and its own install.sh installs it (binary, systemd user unit,
// Brave extension, native-messaging manifest, the brave-flags.conf line),
// keeping a copy of itself in ~/.local/share/intentional for `check`, which
// prints the installed version.
// usage: intentional.ts [check|install]
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { $, executable, main, out } from "#loadout";

const REPO = "https://github.com/josemiguelo/intentional";
const INSTALLED = `${process.env.XDG_DATA_HOME || `${process.env.HOME}/.local/share`}/intentional/install.sh`;

/** The installed install.sh's own check, its output (the version line the manifest's regex reads) passed through. */
async function ready() {
  if (!executable(INSTALLED)) return false;
  return (await $`sh ${INSTALLED} check`.nothrow()).exitCode === 0;
}

/** url's body into path; an HTTP error throws (curl's -f). */
async function download(url: string, path: string) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${url}: ${response.status} ${response.statusText}`);
  await Bun.write(path, response);
}

/** The latest release's version: /releases/latest redirects to /releases/tag/v<version>. */
async function latest() {
  const response = await fetch(`${REPO}/releases/latest`);
  await response.body?.cancel();
  if (!response.ok) throw new Error(`${REPO}/releases/latest: ${response.status} ${response.statusText}`);
  const url = response.url;
  const at = url.lastIndexOf("/v");
  const version = at < 0 ? url : url.slice(at + 2);
  if (!/^[0-9.]+$/.test(version)) throw new Error("no Intentional release found");
  return version;
}

async function install() {
  if (process.platform !== "linux" || process.arch !== "x64") {
    throw new Error(`no Intentional build for ${await out($`uname -s`)} ${await out($`uname -m`)}`);
  }
  const version = await latest();
  const file = `intentional-${version}-linux-x64.tar.gz`;
  const base = `${REPO}/releases/download/v${version}/${file}`;

  const tmp = await mkdtemp(join(tmpdir(), "intentional-"));
  try {
    await download(base, `${tmp}/${file}`);
    const sums = await fetch(`${base}.sha256`);
    if (!sums.ok) throw new Error(`${base}.sha256: ${sums.status} ${sums.statusText}`);
    const want = (await sums.text()).split(" ")[0];
    const got = new Bun.CryptoHasher("sha256").update(await Bun.file(`${tmp}/${file}`).arrayBuffer()).digest("hex");
    if (!want || got !== want) throw new Error(`${file} doesn't match its SHA-256`);

    await $`tar -xzf ${`${tmp}/${file}`} -C ${tmp}`;
    await $`sh ${`${tmp}/intentional-${version}/install.sh`} install`;
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }
}

await main(ready, install);
