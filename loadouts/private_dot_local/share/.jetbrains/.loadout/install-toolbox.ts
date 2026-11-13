#!/usr/bin/env bun
// JetBrains Toolbox on Linux as a per-user install, straight from JetBrains'
// release feed. Not a brew cask: casks that write into $HOME record absolute
// paths in the shared Caskroom, so a prefix shared between accounts breaks on
// the next upgrade ("Permission denied ... /home/<other user>/.config").
//
// Lands where Toolbox installs itself, so its own self-updates replace the
// same files. `check` reads the build.txt JetBrains ships in bin/: a
// self-update replaces bin/ whole, so a file of our own there would vanish
// (and loadout would call Toolbox missing), while build.txt stays current.
// usage: install-toolbox.ts [check|install]; check prints the installed version.
import { existsSync, lstatSync } from "node:fs";
import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { $, brew, brewPrefix, executable, main } from "#loadout";

const HOME = process.env.HOME;
const TOOLBOX_DIR = `${HOME}/.local/share/JetBrains/Toolbox`;
const BIN_DIR = `${TOOLBOX_DIR}/bin`;
const LINK = `${HOME}/.local/bin/jetbrains-toolbox`;
const DESKTOP = `${HOME}/.local/share/applications/jetbrains-toolbox.desktop`;
const FEED = "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release";

/** The feed's answer, as far as it's read. */
type Feed = { TBA: { build: string; downloads: { linux: { link: string } } }[] };

const isLink = (path: string) => {
  try {
    return lstatSync(path).isSymbolicLink();
  } catch {
    return false;
  }
};

/** Installed and linked: prints build.txt as it is, the version the manifest's regex reads. */
async function ready() {
  if (!executable(`${BIN_DIR}/jetbrains-toolbox`) || !isLink(LINK)) return false;
  const build = Bun.file(`${BIN_DIR}/build.txt`);
  if (!(await build.exists())) return false;
  process.stdout.write(await build.bytes());
  return true;
}

async function install() {
  const feed = await fetch(FEED);
  if (!feed.ok) throw new Error(`${FEED}: ${feed.status} ${feed.statusText}`);
  const { build, downloads } = ((await feed.json()) as Feed).TBA[0];
  const url = downloads.linux.link;

  const tmp = await mkdtemp(join(tmpdir(), "toolbox-"));
  try {
    const archive = await fetch(url);
    if (!archive.ok) throw new Error(`${url}: ${archive.status} ${archive.statusText}`);
    await Bun.write(`${tmp}/toolbox.tar.gz`, archive);
    await $`tar -xz -C ${tmp} -f ${`${tmp}/toolbox.tar.gz`}`;

    await mkdir(BIN_DIR, { recursive: true });
    await mkdir(`${HOME}/.local/bin`, { recursive: true });
    await mkdir(dirname(DESKTOP), { recursive: true });
    await $`cp -R ${`${tmp}/jetbrains-toolbox-${build}/bin/.`} ${`${BIN_DIR}/`}`;
    await $`ln -sfn ${`${BIN_DIR}/jetbrains-toolbox`} ${LINK}`;
  } finally {
    await rm(tmp, { recursive: true, force: true });
  }

  // Toolbox rewrites this with its own entry (and icon) on first run.
  if (!existsSync(DESKTOP)) {
    await Bun.write(
      DESKTOP,
      `[Desktop Entry]
Type=Application
Name=JetBrains Toolbox
Exec=${BIN_DIR}/jetbrains-toolbox %u
Icon=${BIN_DIR}/toolbox-tray-color.png
Categories=Development
StartupWMClass=jetbrains-toolbox
Terminal=false
MimeType=x-scheme-handler/jetbrains;
`,
    );
  }

  // Migration from the cask this replaced: the shared prefix must not keep a
  // cask record pointing at another account's home, or `brew upgrade --cask`
  // fails for everyone. Whole-directory removal because `brew uninstall`
  // itself trips over those paths.
  const prefix = await brewPrefix();
  const caskroom = `${prefix}/Caskroom/jetbrains-toolbox-linux`;
  if (existsSync(caskroom)) {
    console.log(`removing stale cask record ${caskroom}`);
    await rm(caskroom, { recursive: true, force: true });
    if (isLink(`${prefix}/bin/jetbrains-toolbox`)) await rm(`${prefix}/bin/jetbrains-toolbox`, { force: true });
  }

  // The cask's tap has no other consumer; left tapped-but-untrusted it makes
  // every brew command warn for accounts that never trusted it.
  const tap = await brew("tap-info", "ublue-os/tap").quiet().nothrow();
  if (tap.stdout.toString().includes("Installed")) await brew("untap", "ublue-os/tap");

  console.log(`jetbrains-toolbox ${build} installed in ${BIN_DIR}`);
}

await main(ready, install);
