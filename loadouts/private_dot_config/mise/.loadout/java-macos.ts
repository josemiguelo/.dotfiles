#!/usr/bin/env bun
// macOS: every JDK the mise config pins, registered with macOS in
// /Library/Java/JavaVirtualMachines — what asdf-java's
// java_macos_integration_enable did. That directory is where
// /usr/libexec/java_home, the /usr/bin/java stub, GUI apps and Gradle's
// toolchain detection look; mise alone only reaches the shell's PATH.
//
// Each JDK gets `mise-<version>.jdk/Contents` linked to its mise install. The
// script only ever touches entries whose link points into mise's or asdf's
// installs — never a JDK some vendor installer put there — and removes those
// that no longer match the config (asdf's, once ~/.asdf is gone, point at
// nothing).
// Modes: `check` / `install` (default).
import { existsSync, readdirSync, readlinkSync } from "node:fs";
import { $, main } from "#loadout";

const HOME = process.env.HOME!;
const JVM = process.env.JVM_DIR || "/Library/Java/JavaVirtualMachines";
const MISE_JAVA = `${process.env.MISE_DATA_DIR || `${process.env.XDG_DATA_HOME || `${HOME}/.local/share`}/mise`}/installs/java`;

const link = (path: string) => {
  try {
    return readlinkSync(path);
  } catch {
    return undefined;
  }
};

/**
 * "<entry> → <Contents target>" for every JDK the config pins that mise has
 * installed. A build without Contents/ (not a macOS bundle) can't register.
 * If mise can't answer, stop: an empty answer would make every registration
 * look stale, and install would remove them all.
 */
async function wanted(): Promise<Map<string, string>> {
  if (!Bun.which("mise")) throw new Error("mise not found");
  const listed = await $`mise ls --global java`.cwd(HOME).quiet().nothrow();
  if (listed.exitCode !== 0) throw new Error(`mise couldn't list the configured java versions:\n${listed.stderr}`);
  const want = new Map<string, string>();
  for (const line of listed.stdout.toString().split("\n")) {
    const [tool, version, source] = line.trim().split(/\s+/);
    if (tool !== "java" || source === "(missing)") continue;
    const where = await $`mise where ${`java@${version}`}`.cwd(HOME).quiet().nothrow();
    if (where.exitCode !== 0) continue;
    const dir = where.stdout.toString().trim();
    if (existsSync(`${dir}/Contents`)) want.set(`${JVM}/mise-${version}.jdk`, `${dir}/Contents`);
    else console.error(`java ${version} has no Contents/ to register (${dir})`);
  }
  return want;
}

/**
 * Entries in JVM that are ours: the entry itself, its Contents, or its
 * Contents/Home links into mise's or asdf's installs. Every entry, not only
 * *.jdk: asdf-java's are stubs named without the suffix
 * (adoptopenjdk-21.0.6+7.0.LTS/Contents/{Info.plist,MacOS,Home ->
 * ~/.asdf/installs/java/…}), which break once ~/.asdf is gone.
 */
function ours() {
  if (!existsSync(JVM)) return [];
  return readdirSync(JVM)
    .map((name) => `${JVM}/${name}`)
    .filter((e) => {
      const target = link(e) ?? link(`${e}/Contents`) ?? link(`${e}/Contents/Home`) ?? "";
      return target.startsWith(`${MISE_JAVA}/`) || target.startsWith(`${HOME}/.asdf/`);
    });
}

const stale = (want: Map<string, string>) => ours().filter((e) => !want.has(e));
const wrong = (want: Map<string, string>) => [...want].filter(([e, target]) => link(`${e}/Contents`) !== target).map(([e]) => e);

async function ready() {
  const want = await wanted();
  const s = stale(want);
  const w = wrong(want);
  for (const e of s) console.log(`stale: ${e}`);
  for (const e of w) console.log(`missing: ${e}`);
  return s.length === 0 && w.length === 0;
}

async function install() {
  const want = await wanted();
  for (const e of stale(want)) {
    console.log(`removing ${e}`);
    await $`sudo rm -rf ${e}`;
  }
  for (const [e, target] of want) {
    if (link(`${e}/Contents`) === target) continue;
    console.log(`registering ${e}`);
    await $`sudo mkdir -p ${e}`;
    await $`sudo ln -sfn ${target} ${`${e}/Contents`}`;
  }
  await $`/usr/libexec/java_home -V`.nothrow();
}

await main(ready, install);
