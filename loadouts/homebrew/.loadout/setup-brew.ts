// Homebrew on Linux, owned by the login user. Single source of truth for the
// directories Homebrew itself demands write access to; the prefix comes from
// brew-prefix.sh.
//
// check   brew binary present and every DIR writable by $USER
// install install Homebrew if missing (official installer, non-interactive),
//         then chown the prefix to $USER if any part of it is owned by
//         someone else
import { accessSync, constants, existsSync } from "node:fs";
import { $, executable, fail } from "loadout/script";
import { brewPrefix } from "#brew";

const INSTALLER = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh";

// The directories `brew install` refuses to run without write access to.
const DIRS = ["Cellar", "Homebrew", "bin", "etc", "include", "lib", "opt", "sbin", "share", "var/homebrew/linked", "var/homebrew/locks", "var/log"];

const PREFIX = await brewPrefix();
const BREW = `${PREFIX}/bin/brew`;

/** Can this user write to path? (sh's `[ -w path ]`) */
function canWrite(path: string) {
  try {
    accessSync(path, constants.W_OK);
    return true;
  } catch {
    return false;
  }
}

/** brew is there, and every DIR that exists is writable. */
export const check = () => executable(BREW) && DIRS.every((d) => !existsSync(`${PREFIX}/${d}`) || canWrite(`${PREFIX}/${d}`));

export async function install() {
  const user = process.env.USER || fail("USER isn't set");
  if (!executable(BREW)) {
    const script = await $`curl -fsSL ${INSTALLER}`.quiet().text();
    await $`/bin/bash -c ${script}`.env({ ...process.env, NONINTERACTIVE: "1" });
  }
  // Anything under the prefix someone else owns; find's errors (unreadable
  // folders) are no answer.
  const foreign = await $`find ${PREFIX} ${"!"} -user ${user} -print -quit`.quiet().nothrow();
  if (foreign.stdout.toString().trim() !== "") {
    console.log(`reclaiming ${PREFIX} for ${user}`);
    await $`sudo chown -R ${user} ${PREFIX}`;
  }
  if (!check()) fail(`${PREFIX} is still not writable by ${user}`);
}
