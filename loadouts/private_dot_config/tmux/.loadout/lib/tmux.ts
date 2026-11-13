// tmux's plugins for plugins.ts and outdated-plugins.ts: the ones tmux.conf
// declares (`set -g @plugin 'owner/repo'`; the file comes from the chezmoi
// dotfiles) and the clones tpack made of them.
import { existsSync, readdirSync, statSync } from "node:fs";
import { read } from "loadout/script";
import { brewPrefix } from "#brew";

const HOME = process.env.HOME!;
const CONFIG = process.env.XDG_CONFIG_HOME || `${HOME}/.config`;
const DATA = process.env.XDG_DATA_HOME || `${HOME}/.local/share`;

export const CONF = `${CONFIG}/tmux/tmux.conf`;

/**
 * tpack clones under XDG_DATA_HOME (~/.local/share/tmux/plugins); older setups
 * kept them next to tmux.conf. Both are walked.
 */
const CLONES = [`${DATA}/tmux/plugins`, `${CONFIG}/tmux/plugins`];

/** PATH with ~/.local/bin (tpack's release) and brew's bin first. */
export const toolsPath = async () => [`${HOME}/.local/bin`, `${await brewPrefix()}/bin`, process.env.PATH].join(":");

/** One "<owner/repo>" per declared plugin, comments dropped. */
export async function declared(): Promise<string[]> {
  const plugins = [];
  for (const line of (await read(CONF)).split("\n")) {
    const m = line.match(/^\s*set\s*-g\s*@plugin\s*['"]([^'"#]*)/);
    if (m) plugins.push(m[1]);
  }
  return plugins;
}

/** The clone of repo (tpack names it <repo>-<12-hex-hash>), undefined when there's none. */
export function cloneOf(repo: string): string | undefined {
  const name = repo.split("/").pop()!;
  for (const base of CLONES) {
    if (!existsSync(base)) continue;
    for (const dir of readdirSync(base)) {
      if (!dir.startsWith(`${name}-`)) continue;
      try {
        if (statSync(`${base}/${dir}/.git`).isDirectory()) return `${base}/${dir}`;
      } catch {
        // Not a clone.
      }
    }
  }
  return undefined;
}
