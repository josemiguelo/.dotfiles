#!/usr/bin/env bun
// mise tools: every version ~/.config/mise/config.toml pins (the file comes
// from the chezmoi dotfiles; the mise-tools oracle moves its pins) is
// installed. No plugin step: mise resolves every tool from its own
// registry. Lazy tools (Omarchy 4.5's agents, /etc/mise/conf.d) install on
// first use and `mise install` skips them, so they count as present.
//
// Named tools (`tools.ts node python`) narrow it to each one's default
// version, the first config.toml lists (what a shell gets): the core of a
// setup, with mise-tools-later (no names) installing the rest afterwards.
// One config.toml either way: mise hides a tool's versions in a second file
// whenever config.toml lists that tool too, so the split is in what's
// installed, not in the files. Names, not versions, so a pin the oracle
// moves needs no change here.
// usage: tools.ts [check|install] [tool...]
import { existsSync, statSync } from "node:fs";
import { $, fail, has, main } from "#loadout";

if (!has("mise")) fail("mise not found");

// Every mise command runs from $HOME, for the global config only: from the
// repo's cwd mise would also look for project configs in its parents.
const HOME = process.env.HOME!;

/** Is tool@version installed? */
const installed = async (tool: string, v: string) => (await $`mise where ${`${tool}@${v}`}`.cwd(HOME).quiet().nothrow()).exitCode === 0;

/** The default version of each named tool that isn't installed, as tool@version. */
async function missingDefaults(tools: string[]) {
  const missing: string[] = [];
  for (const tool of tools) {
    const current = await $`mise current ${tool}`.cwd(HOME).quiet().nothrow();
    const v = current.stdout.toString().trim().split(/\s+/)[0];
    if (!v) throw new Error(`${tool} isn't in mise's config`);
    if (!(await installed(tool, v))) missing.push(`${tool}@${v}`);
  }
  return missing;
}

/**
 * `mise ls --missing [tool]`'s rows, split into fields, with whether the row
 * says "(lazy)". Captured first and
 * failing loudly: a mise error (an untrusted or broken config) prints
 * nothing, which would read as "nothing missing". mise's own stderr is passed
 * on, as the sh did.
 */
async function lsMissing(...tool: string[]) {
  const listed = await $`mise ls --missing ${tool}`.cwd(HOME).quiet().nothrow();
  process.stderr.write(listed.stderr);
  if (listed.exitCode !== 0) throw new Error("mise ls --missing failed");
  return listed.stdout
    .toString()
    .split("\n")
    .filter((line) => line.trim())
    .map((line) => ({ lazy: line.includes("(lazy)"), fields: line.trim().split(/\s+/) }));
}

function report(missing: string[]) {
  for (const m of missing) console.log(`missing: ${m}`);
  return missing.length === 0;
}

async function ready(...tools: string[]) {
  if (tools.length > 0) return report(await missingDefaults(tools));
  const rows = await lsMissing();
  return report(rows.filter((row) => !row.lazy).map(({ fields: [tool, version] }) => `${tool}@${version ?? ""}`));
}

async function install(...tools: string[]) {
  if (tools.length > 0) {
    let missing = await missingDefaults(tools);
    if (missing.length > 0) await $`mise install ${missing}`.cwd(HOME);
    missing = await missingDefaults(tools);
    if (missing.length > 0) throw new Error(`still missing after mise install: ${missing.join("\n")}`);
    return;
  }
  // Python 2.x builds from source, and its ssl module only against OpenSSL
  // 1.x: where openssl-1.1 sits beside the system's (Arch, the AUR's
  // package), those versions build first, pointed at it. Only them: the
  // flags would also reach any other tool mise compiles.
  const ssl11 = "/usr/include/openssl-1.1";
  if (existsSync(ssl11) && statSync(ssl11).isDirectory()) {
    for (const { fields: [, v] } of await lsMissing("python")) {
      if (!v?.startsWith("2.")) continue;
      await $`mise install ${`python@${v}`}`.cwd(HOME).env({ ...process.env, CPPFLAGS: `-I${ssl11}`, LDFLAGS: "-L/usr/lib/openssl-1.1" });
    }
  }
  await $`mise install`.cwd(HOME);
}

await main(ready, install);
