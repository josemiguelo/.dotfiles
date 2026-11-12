#!/usr/bin/env bun
// The KaiT2en -> Omarchy development setup (docs/t2-macbook.md), on top of the
// bare clones bare-repos makes of t2-arch-packages, omarchy and omarchy-iso:
//
// - the forks (omarchy, omarchy-iso): an `upstream` remote (omacom/<repo>) and
//   the fork's T2 branch checked out in all_worktrees/<branch>: omarchy's
//   t2-kait2en-stable (the T2 commits on Omarchy's stable release, its only
//   branch on GitHub; the ISO installs from it) and omarchy-iso's t2-kait2en
//   (the ISO builder, whose --stable builds stable ISOs);
// - clones kait2en-sync and the ISO build read: KaiT2en upstream and
//   omacom/omarchy-pkgs, in ~/Repos/gh/<owner>/<repo> like gclone's;
// - libvfio-user with its gpio-pci-idio-16 sample built, the fake-hardware
//   server of `omarchy-iso-test --fake-pci` (its build deps are the machine's
//   omarchy_iso_test_deps);
// - the [t2-arch-packages] signing key in gpg, from the 1Password item
//   "kait2en" (Personal vault), trusted ultimately, so kait2en-sync can sign;
// - a daily user timer running `kait2en-sync notify`: a desktop notification
//   when KaiT2en changes a package, or when a new linux-omarchy would break a
//   T2 module (before Omarchy ships it).
//
// check: all of the above in place (says what's missing). install: whichever
// isn't. Existing clones are only fetched, never reset.
// Modes: `check` / `install` (default).
import { existsSync, mkdirSync, accessSync, constants } from "node:fs";
import { dirname } from "node:path";
import { $, main, ok, read } from "#loadout";
import { opUnlocked } from "#onepassword";

const HOME = process.env.HOME!;
const REPOS = `${HOME}/Repos/gh`;
const FPR = "077D8295CCF834D3F5EC25F70506B72C34EB162F";
const KEY_REF = "op://Personal/kait2en/t2-arch-packages-signing-key.asc";
const VFIO = `${REPOS}/nutanix/libvfio-user`;
const VFIO_BIN = `${VFIO}/build/samples/gpio-pci-idio-16`;
const UNITS = `${process.env.XDG_CONFIG_HOME || `${HOME}/.config`}/systemd/user`;
const SYNC = `${REPOS}/josemiguelo/t2-arch-packages/all_worktrees/main/bin/kait2en-sync`;
// Each fork's T2 branch, the one checked out and built from.
const BRANCHES: Record<string, string> = { omarchy: "t2-kait2en-stable", "omarchy-iso": "t2-kait2en" };
const FORKS = Object.keys(BRANCHES);
const CLONES = ["kaiT2en/KaiT2en-Fedora", "omacom/omarchy-pkgs"];

const SERVICE = `# Managed by loadout (kait2en-dev).
[Unit]
Description=Check KaiT2en and linux-omarchy for changes to the T2 packages

[Service]
Type=oneshot
ExecStart=${SYNC} notify
`;

const TIMER = `# Managed by loadout (kait2en-dev).
[Unit]
Description=Daily check of KaiT2en and linux-omarchy for the T2 packages

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=30min

[Install]
WantedBy=timers.target
`;

const forkDir = (repo: string) => `${REPOS}/josemiguelo/${repo}`;
const upstream = (repo: string) => `https://github.com/omacom/${repo}.git`;

async function forkOk(repo: string) {
  const dir = forkDir(repo);
  const url = (await $`git -C ${dir} config --get remote.upstream.url`.quiet().nothrow()).stdout.toString().trim();
  return url === upstream(repo) && existsSync(`${dir}/all_worktrees/${BRANCHES[repo]}`);
}

async function forkInstall(repo: string) {
  const dir = forkDir(repo);
  if (!existsSync(dir)) throw new Error(`kait2en-dev: ${dir} missing (bare-repos clones it)`);
  if (await ok($`git -C ${dir} remote get-url upstream`)) await $`git -C ${dir} remote set-url upstream ${upstream(repo)}`;
  else await $`git -C ${dir} remote add upstream ${upstream(repo)}`;
  await $`git -C ${dir} config remote.upstream.pushurl no_push`;
  await $`git -C ${dir} fetch --quiet origin`;
  await $`git -C ${dir} fetch --quiet upstream`;
  const branch = BRANCHES[repo];
  const worktree = `${dir}/all_worktrees/${branch}`;
  if (!existsSync(worktree)) {
    if (await ok($`git -C ${dir} show-ref --verify --quiet refs/heads/${branch}`)) {
      await $`git -C ${dir} worktree add --quiet ${worktree} ${branch}`;
    } else {
      await $`git -C ${dir} worktree add --quiet -b ${branch} ${worktree} origin/${branch}`;
    }
    await $`git -C ${worktree} branch --quiet --set-upstream-to=origin/${branch} ${branch}`;
    console.log(`kait2en-dev: ${repo}'s ${branch} checked out in ${worktree}`);
  }
}

const cloneOk = (repo: string) => existsSync(`${REPOS}/${repo}/.git`);

async function cloneInstall(repo: string) {
  if (cloneOk(repo)) {
    await $`git -C ${`${REPOS}/${repo}`} fetch --quiet origin`.nothrow();
    return;
  }
  console.log(`kait2en-dev: cloning ${repo}`);
  mkdirSync(dirname(`${REPOS}/${repo}`), { recursive: true });
  await $`git clone --quiet https://github.com/${repo}.git ${`${REPOS}/${repo}`}`;
}

const vfioOk = () => {
  try {
    accessSync(VFIO_BIN, constants.X_OK);
    return true;
  } catch {
    return false;
  }
};

async function vfioInstall() {
  await cloneInstall("nutanix/libvfio-user");
  if (!existsSync(`${VFIO}/build`)) await $`meson setup build . -Ddefault_library=static`.cwd(VFIO).quiet();
  await $`ninja -C ${`${VFIO}/build`} samples/gpio-pci-idio-16`.quiet();
}

const keyOk = () => ok($`gpg --list-secret-keys ${FPR}`);

async function keyInstall() {
  await opUnlocked("kait2en-dev");
  await $`op read ${KEY_REF} | gpg --batch --quiet --import`;
  await $`echo ${`${FPR}:6:`} | gpg --quiet --import-ownertrust`;
}

const unitsOk = async () =>
  (await read(`${UNITS}/kait2en-sync.service`)) === SERVICE &&
  (await read(`${UNITS}/kait2en-sync.timer`)) === TIMER &&
  (await ok($`systemctl --user -q is-enabled kait2en-sync.timer`));

async function unitsInstall() {
  mkdirSync(UNITS, { recursive: true });
  await Bun.write(`${UNITS}/kait2en-sync.service`, SERVICE);
  await Bun.write(`${UNITS}/kait2en-sync.timer`, TIMER);
  await $`systemctl --user daemon-reload`;
  await $`systemctl --user enable --now kait2en-sync.timer`;
}

/** Everything in place; says what isn't. */
async function check() {
  const missing: string[] = [];
  for (const repo of FORKS) if (!(await forkOk(repo))) missing.push(`${repo} upstream remote or ${BRANCHES[repo]} worktree`);
  for (const repo of CLONES) if (!cloneOk(repo)) missing.push(repo);
  if (!vfioOk()) missing.push(VFIO_BIN);
  if (!(await keyOk())) missing.push(`signing key ${FPR}`);
  if (!(await unitsOk())) missing.push("kait2en-sync.timer");
  for (const m of missing) console.log(`missing: ${m}`);
  return missing.length === 0;
}

async function install() {
  for (const repo of FORKS) if (!(await forkOk(repo))) await forkInstall(repo);
  for (const repo of CLONES) await cloneInstall(repo);
  if (!vfioOk()) await vfioInstall();
  if (!(await keyOk())) await keyInstall();
  if (!(await unitsOk())) await unitsInstall();
  if (!(await check())) throw new Error("kait2en-dev isn't fully set up after install");
}

await main(check, install);
