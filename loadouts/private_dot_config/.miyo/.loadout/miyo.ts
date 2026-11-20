#!/usr/bin/env bun
// Miyo's latest Linux AppImage (github.com/Brevilabs/miyo-releases), checked
// against the SHA-512 in the release's latest-linux.yml, kept as
// ~/.local/share/miyo/Miyo.AppImage and linked as ~/.local/bin/miyo-app
// (`miyo` is Miyo's own CLI, in ~/.miyo/bin). The name has no version on
// purpose: Miyo updates itself (electron-updater), which replaces a
// version-less file in place but deletes a versioned one for the new
// version's name, which would leave the link and the launcher dangling.
// usage: miyo.ts [check|install]
import { chmodSync, mkdirSync, readdirSync, readlinkSync, renameSync, rmSync, symlinkSync } from "node:fs";
import { executable, fail, main } from "loadout/script";

const RELEASES = "https://github.com/Brevilabs/miyo-releases/releases";
const HOME = process.env.HOME!;
const DIR = `${process.env.XDG_DATA_HOME || `${HOME}/.local/share`}/miyo`;
const APP = `${DIR}/Miyo.AppImage`;
const LINK = `${HOME}/.local/bin/miyo-app`;

function ready() {
  try {
    return readlinkSync(LINK) === APP && executable(APP);
  } catch {
    return false;
  }
}

/** latest-linux.yml's AppImage name and its SHA-512 (base64, as electron-builder writes it). */
async function latest() {
  const response = await fetch(`${RELEASES}/latest/download/latest-linux.yml`);
  if (!response.ok) fail(`${RELEASES}/latest/download/latest-linux.yml: ${response.status} ${response.statusText}`);
  const yml = await response.text();
  const path = yml.match(/^path:\s*(\S+)$/m)?.[1];
  const sha512 = yml.match(/^sha512:\s*(\S+)$/m)?.[1];
  const version = yml.match(/^version:\s*(\S+)$/m)?.[1];
  if (!path || !sha512 || !version || !path.endsWith(".AppImage")) fail("no Miyo AppImage in latest-linux.yml");
  return { path, sha512, version };
}

const sha512Of = async (file: string) =>
  new Bun.CryptoHasher("sha512").update(await Bun.file(file).arrayBuffer()).digest("base64");

async function install() {
  if (process.platform !== "linux" || process.arch !== "x64") fail("Miyo publishes a Linux AppImage for x86_64 only");
  mkdirSync(DIR, { recursive: true });
  // An AppImage already here, under a versioned name from an earlier install
  // or already in place, is kept: Miyo updates it itself from then on.
  if (!executable(APP)) {
    const earlier = readdirSync(DIR).find((f) => /^Miyo-.*\.AppImage$/.test(f));
    if (earlier) renameSync(`${DIR}/${earlier}`, APP);
  }
  if (!executable(APP)) {
    const { path, sha512, version } = await latest();
    const part = `${APP}.part`;
    const response = await fetch(`${RELEASES}/download/v${version}/${path}`);
    if (!response.ok) fail(`${path}: ${response.status} ${response.statusText}`);
    await Bun.write(part, response);
    if ((await sha512Of(part)) !== sha512) {
      rmSync(part, { force: true });
      fail(`${path} doesn't match its SHA-512`);
    }
    chmodSync(part, 0o755);
    renameSync(part, APP);
  }
  mkdirSync(`${HOME}/.local/bin`, { recursive: true });
  rmSync(LINK, { force: true }); // a dangling link too
  symlinkSync(APP, LINK);
  // Versioned copies an older install or an update left behind.
  for (const f of readdirSync(DIR)) if (/^Miyo-.*\.AppImage$/.test(f)) rmSync(`${DIR}/${f}`, { force: true });
}

await main(ready, install);
