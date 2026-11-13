#!/usr/bin/env bun
// tpack's latest GitHub release into ~/.local/bin, on Linux. The tpack cask
// depends on brew's tmux and git, which land ahead of the system's on PATH;
// Linux takes tmux from the system (Omarchy), so tpack comes from its
// release instead: a static binary, checked against the release's checksums.
// Run again, it installs the newest release over the old one.
// usage: install-tpack.ts
import { mkdir, mkdtemp, rename, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { $, out, run } from "#loadout";

const BIN_DIR = `${process.env.HOME}/.local/bin`;
const REPO = "https://github.com/tmuxpack/tpack";

/** The release's name for each process.arch. */
const ARCHES: Record<string, string> = { x64: "amd64", arm64: "arm64" };

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
  if (!version) throw new Error("no tpack release found");
  return version;
}

async function install() {
  const arch = ARCHES[process.arch];
  if (!arch) throw new Error(`unsupported architecture: ${await out($`uname -m`)}`);
  const version = await latest();
  const file = `tpack_${version}_linux_${arch}.tar.gz`;
  const base = `${REPO}/releases/download/v${version}`;

  const tmp = await mkdtemp(join(tmpdir(), "tpack-"));
  try {
    await download(`${base}/${file}`, `${tmp}/${file}`);
    const sums = await fetch(`${base}/checksums.txt`);
    if (!sums.ok) throw new Error(`${base}/checksums.txt: ${sums.status} ${sums.statusText}`);
    // checksums.txt is sha256sum's "<sha>  <file>" lines.
    const line = (await sums.text()).split("\n").find((l) => l.endsWith(`  ${file}`));
    if (!line) throw new Error(`no checksum for ${file} in checksums.txt`);
    const got = new Bun.CryptoHasher("sha256").update(await Bun.file(`${tmp}/${file}`).arrayBuffer()).digest("hex");
    if (got !== line.split(" ")[0]) throw new Error(`${file}: FAILED (doesn't match checksums.txt)`);
    console.log(`${file}: OK`);
    await $`tar -xzf ${`${tmp}/${file}`} -C ${tmp} tpack`;

    await mkdir(BIN_DIR, { recursive: true });
    // Renamed into place from the same folder, not copied over: a running
    // tpack keeps its own file.
    await $`install -m 755 ${`${tmp}/tpack`} ${`${BIN_DIR}/.tpack.new`}`;
    await rename(`${BIN_DIR}/.tpack.new`, `${BIN_DIR}/tpack`);
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }
}

await run(install);
