// Homebrew, as this repo's scripts reach it: its prefix from brew-prefix.sh
// (the one place that decides it, which zsh sources too) and brew by its
// path. What every script shares otherwise is loadout's own script SDK
// ("loadout/script").
import { $, executable, repoPath } from "loadout/script";

let prefix: string | undefined;

/** brew-prefix.sh's answer, asked once per script and synchronously, so brew() can build its command at once. */
function brewPrefixNow(): string {
  if (prefix === undefined) {
    const sh = Bun.spawnSync(["sh", "-c", '. "$1"; printf %s "$BREW_PREFIX"', "sh", repoPath("loadouts/private_dot_local/lib/brew-prefix.sh")]);
    if (!sh.success) throw new Error(sh.stderr.toString().trim() || `brew-prefix.sh exited ${sh.exitCode}`);
    prefix = sh.stdout.toString().trim();
  }
  return prefix;
}

/**
 * Homebrew's prefix on this OS, from brew-prefix.sh, the one place that
 * decides it (the sh scripts source it). By OS, not by what exists: check for
 * `${prefix}/bin/brew` before relying on it.
 */
export const brewPrefix = async () => brewPrefixNow();

/**
 * brew by absolute path, as every brew command the repo runs itself: converging
 * never depends on a shell having run `brew shellenv` (on a fresh machine the
 * dotfiles that do that come AFTER the programs). A PATH brew comes first, so
 * a custom prefix still works, then this OS's prefix (brew-prefix.sh, asked
 * only when PATH has none). Unattended: Homebrew asks before an install that
 * pulls in dependencies, and HOMEBREW_NO_ASK stops that. Without brew, a
 * command that fails saying so. loadout's own brew installers find brew
 * through setup-brew's `provides` instead.
 */
export function brew(...args: string[]) {
  const found = Bun.which("brew");
  const bin = found && executable(found) ? found : `${brewPrefixNow()}/bin/brew`;
  if (!executable(bin)) return $`echo ${"brew is not installed (setup-brew installs it on Linux)"} 1>&2 && exit 1`;
  return $`${bin} ${args}`.env({ ...process.env, HOMEBREW_NO_ASK: "1" });
}
