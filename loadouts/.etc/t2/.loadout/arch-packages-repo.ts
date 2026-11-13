#!/usr/bin/env bun
// The [t2-arch-packages] pacman repo: KaiT2en's T2 drivers and tools packaged
// for linux-omarchy (github.com/josemiguelo/t2-arch-packages), signed with
// FPR below (t2-arch-packages.asc, beside this script).
//
// Omarchy's installer adds the repo on T2 Macs (the t2-kait2en branch's
// install/hardware/pacman.sh), but `omarchy refresh pacman` and channel
// switches rewrite /etc/pacman.conf from Omarchy's channel template, without
// it. They run ~/.config/omarchy/hooks/pre-refresh-pacman.d/* right after, so
// a hook there puts it back. pacman-conf follows Includes, so the repo counts
// whether pacman.conf names it itself or includes a file that does (another
// hook's /etc/pacman.d/custom-repos.conf); either way it is never added twice.
//
// check: the repo is configured, its key is trusted (locally signed or
// populated from t2-arch-packages-keyring), and the hook is in place.
// install: whichever of those is missing.
// usage: arch-packages-repo.ts [check|install]
import { chmod, mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { $, executable, main, readTrimmed } from "#loadout";

const REPO = "t2-arch-packages";
const SERVER = "https://github.com/josemiguelo/t2-arch-packages/releases/download/repo";
const FPR = "077D8295CCF834D3F5EC25F70506B72C34EB162F";
const KEY = `${import.meta.dir}/t2-arch-packages.asc`;
const HOOK = `${process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`}/omarchy/hooks/pre-refresh-pacman.d/t2-arch-packages`;
const ENTRY = `\n[${REPO}]\nServer = ${SERVER}\n`;

const HOOK_TEXT = `#!/bin/bash
# Managed by loadout (t2-arch-packages-repo): \`omarchy refresh pacman\` just
# rewrote /etc/pacman.conf from Omarchy's channel template; put the signed
# [${REPO}] repo back, unless something already configures it.
pacman-conf --repo-list 2>/dev/null | grep -qx ${REPO} && exit 0
printf '\\n[%s]\\nServer = %s\\n' ${REPO} ${SERVER} | sudo tee -a /etc/pacman.conf >/dev/null
`;

const lines = async (command: ReturnType<typeof $>) => (await command.quiet().nothrow()).stdout.toString().split("\n");

const repoReady = async () => (await lines($`pacman-conf --repo-list`)).includes(REPO);

// pacman-key lists the key unprivileged; trusted means full or ultimate validity.
const keyReady = async () => (await lines($`pacman-key --list-keys ${FPR}`)).some((l) => /^uid +\[ *(full|ultimate) *\]/.test(l));

// Compared as sh's $(cat …) did: trailing newlines aside.
const hookReady = async () => executable(HOOK) && (await readTrimmed(HOOK)) === HOOK_TEXT.replace(/\n+$/, "");

const ready = async () => (await repoReady()) && (await keyReady()) && (await hookReady());

async function install() {
  if (!(await keyReady())) {
    await $`sudo pacman-key --add ${KEY}`;
    await $`sudo pacman-key --lsign-key ${FPR}`;
  }
  if (!(await repoReady())) await $`sudo tee -a /etc/pacman.conf < ${Buffer.from(ENTRY)}`.quiet();
  if (!(await hookReady())) {
    await mkdir(dirname(HOOK), { recursive: true });
    await Bun.write(HOOK, HOOK_TEXT);
    await chmod(HOOK, 0o755);
  }
  if (!(await repoReady())) throw new Error(`pacman doesn't list [${REPO}] after install`);
  if (!(await keyReady())) throw new Error(`pacman doesn't trust ${FPR} after install`);
  if (!(await hookReady())) throw new Error(`${HOOK} not in place after install`);
}

await main(ready, install);
