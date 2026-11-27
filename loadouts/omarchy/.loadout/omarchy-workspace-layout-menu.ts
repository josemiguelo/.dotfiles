// The Omarchy menu's layout entries (Appearance; Keystroke serves the menu):
// "This Workspace's Layout", one entry per layout that changes the focused
// workspace only (omarchy-workspace-layout-set, in ~/.local/bin), beside
// Omarchy's own entry, relabelled "Default Workspace Layout" since it sets the
// layout of new and empty workspaces, never one with windows. The entries are
// omarchy-workspace-layout-menu/menu.jsonc, kept as a block in the menu's
// extensions (menuBlockWrite in lib/omarchy.ts). Done = the block as written
// and the command on the PATH.
import { isOnPath } from "loadout/script";
import { MENU, menuBlockInPlace, menuBlockWrite } from "#omarchy";

const NAME = "omarchy-workspace-layout-menu";
const ENTRIES = `${import.meta.dir}/omarchy-workspace-layout-menu/menu.jsonc`;
const NOTE = "Layout entries under Appearance (loadouts/omarchy/.loadout/omarchy-workspace-layout-menu.ts rewrites this block).";
const COMMAND = "omarchy-workspace-layout-set";

export const check = async () => isOnPath(COMMAND) && (await menuBlockInPlace(NAME, NOTE, ENTRIES));

export async function install() {
  if (!isOnPath(COMMAND)) throw new Error(`${COMMAND} isn't on the PATH: chezmoi apply puts it in ~/.local/bin`);
  await menuBlockWrite(NAME, NOTE, ENTRIES);
  if (!(await check())) throw new Error(`the layout entries aren't in ${MENU} after install`);
}
