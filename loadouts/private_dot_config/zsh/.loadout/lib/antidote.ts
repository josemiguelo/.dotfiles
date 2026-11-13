// antidote and the bundles $ZDOTDIR/.zplugins declares (the file comes from
// the chezmoi dotfiles), for plugins.ts and the outdated oracles. Local
// $ZDOTDIR/... entries are dotfiles, not clones: chezmoi's business.
import { existsSync } from "node:fs";
import { $, out, read } from "#loadout";

const HOME = process.env.HOME!;
const ZDOTDIR = process.env.ZDOTDIR || `${HOME}/.config/zsh`;

export const BUNDLES = `${ZDOTDIR}/.zplugins`;

/** antidote's own clone, where plugins.ts clones it. */
export const ANTIDOTE = `${process.env.XDG_DATA_HOME || `${HOME}/.local/share`}/mattmc3/antidote`;

export const antidoteInstalled = () => existsSync(`${ANTIDOTE}/antidote.zsh`);

/** One "<owner/repo>" per remote bundle, sorted, once each; comments and local entries dropped. */
export async function declared(): Promise<string[]> {
  const repos = new Set<string>();
  for (const line of (await read(BUNDLES)).split("\n")) {
    const m = line.match(/^\s*([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)(\s.*)?$/);
    if (m) repos.add(m[1]);
  }
  return [...repos].sort();
}

/**
 * Each declared bundle and its clone, undefined for one not cloned. Asks
 * antidote (`antidote path`), never guesses: its home differs per OS (macOS:
 * ~/Library/Caches/antidote) and its layout per version (2.x nests clones
 * under github.com/), and each guess once read installed bundles as missing
 * forever. Needs antidote itself; throws when zsh or antidote fails, rather
 * than reading that as no bundle cloned.
 */
export async function bundlePaths(): Promise<{ repo: string; dir?: string }[]> {
  const list = `
    source "$ANTIDOTE/antidote.zsh" || exit 1
    for r in "$@"; do
      p=$(antidote path "$r" 2>/dev/null) && print -r -- "$r $p" || print -r -- "$r -"
    done`;
  const result = await $`zsh -fc ${list} zsh ${await declared()}`.env({ ...process.env, ANTIDOTE }).quiet().nothrow();
  if (result.exitCode !== 0) throw new Error("antidote could not list its bundles");
  return result.stdout
    .toString()
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const [repo, dir] = line.split(" ");
      return { repo, dir: dir === "-" ? undefined : dir };
    });
}

/**
 * Clones every declared bundle that's missing (`antidote bundle`); the script
 * it generates is discarded, as the interactive shell makes its own.
 */
export const bundleAll = () =>
  out($`zsh -c ${'source "$1" && antidote bundle < "$2" > /dev/null'} zsh ${`${ANTIDOTE}/antidote.zsh`} ${BUNDLES}`);
