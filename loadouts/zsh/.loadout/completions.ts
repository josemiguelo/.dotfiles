// Shell completions in the user's completions dir, fetching only what's
// missing: add a line to COMPLETIONS and both check and install follow.
import { existsSync } from "node:fs";
import { mkdir, rename, rm } from "node:fs/promises";

// ZDOTDIR is exported by ~/.zshenv; from bash (a desktop's default shell before
// default-shell has run) it is unset, so fall back to the same directory.
const DIR = `${process.env.ZDOTDIR || `${process.env.HOME}/.config/zsh`}/completions`;

/** Each installed as _<name>, from its url. */
const COMPLETIONS: Record<string, string> = {
  tmuxinator: "https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh",
};

const installed = (name: string) => existsSync(`${DIR}/_${name}`);

export const check = () => Object.keys(COMPLETIONS).every(installed);

export async function install() {
  await mkdir(DIR, { recursive: true });
  for (const [name, url] of Object.entries(COMPLETIONS)) {
    if (installed(name)) continue;
    // Into place only once whole: a broken-off download left at the final
    // name would pass the check forever. The partial is a dotfile: zsh reads
    // every _* file here as a completion.
    const part = `${DIR}/.${name}.part`;
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error(`${url}: ${response.status} ${response.statusText}`);
      await Bun.write(part, response);
      await rename(part, `${DIR}/_${name}`);
    } catch (error) {
      await rm(part, { force: true });
      throw error;
    }
  }
}
