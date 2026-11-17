#!/usr/bin/env bun
// The [t2-arch-packages] pacman repo: KaiT2en's T2 drivers and tools packaged
// for linux-omarchy (github.com/josemiguelo/t2-arch-packages), signed with
// FPR below (t2-arch-packages.asc, beside this script).
//
// Omarchy's installer adds the repo on T2 Macs (the t2-kait2en branch's
// install/hardware/pacman.sh). `omarchy refresh pacman` and channel switches
// rewrite /etc/pacman.conf without it; t2-omarchy-plugins' hook
// (pre-refresh-pacman.d/t2-arch-packages, linked by t2-omarchy-setup) puts it
// back, so this only makes sure it's there. pacman-conf follows Includes, so
// the repo counts whether pacman.conf names it itself or includes a file that
// does; either way it is never added twice.
//
// check: the repo is configured and its key trusted (locally signed or
// populated from t2-arch-packages-keyring).
// install: whichever of those is missing.
// usage: arch-packages-repo.ts [check|install]
import { $, main } from "loadout/script";

const REPO = "t2-arch-packages";
const SERVER = "https://github.com/josemiguelo/t2-arch-packages/releases/download/repo";
const FPR = "077D8295CCF834D3F5EC25F70506B72C34EB162F";
const KEY = `${import.meta.dir}/t2-arch-packages.asc`;
const ENTRY = `\n[${REPO}]\nServer = ${SERVER}\n`;

const lines = async (command: ReturnType<typeof $>) => (await command.quiet().nothrow()).stdout.toString().split("\n");

const repoReady = async () => (await lines($`pacman-conf --repo-list`)).includes(REPO);

// pacman-key lists the key unprivileged; trusted means full or ultimate validity.
const keyReady = async () => (await lines($`pacman-key --list-keys ${FPR}`)).some((l) => /^uid +\[ *(full|ultimate) *\]/.test(l));

const ready = async () => (await repoReady()) && (await keyReady());

async function install() {
  if (!(await keyReady())) {
    await $`sudo pacman-key --add ${KEY}`;
    await $`sudo pacman-key --lsign-key ${FPR}`;
  }
  if (!(await repoReady())) await $`sudo tee -a /etc/pacman.conf < ${Buffer.from(ENTRY)}`.quiet();
  if (!(await repoReady())) throw new Error(`pacman doesn't list [${REPO}] after install`);
  if (!(await keyReady())) throw new Error(`pacman doesn't trust ${FPR} after install`);
}

await main(ready, install);
