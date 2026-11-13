import { atuin } from "../../loadouts/private_dot_config/.atuin.loadout.ts";
import { bat } from "../../loadouts/private_dot_config/.bat.loadout.ts";
import { eza } from "../../loadouts/private_dot_config/.eza.loadout.ts";
import { fd } from "../../loadouts/private_dot_config/.fd.loadout.ts";
import { gitDelta } from "../../loadouts/private_dot_config/.git-delta.loadout.ts";
import { gum } from "../../loadouts/private_dot_config/.gum.loadout.ts";
import { lazydocker } from "../../loadouts/private_dot_config/.lazydocker.loadout.ts";
import { lazygit } from "../../loadouts/private_dot_config/.lazygit.loadout.ts";
import { ripgrep } from "../../loadouts/private_dot_config/.ripgrep.loadout.ts";
import { starship } from "../../loadouts/private_dot_config/.starship.loadout.ts";
import { treeSitterCli } from "../../loadouts/private_dot_config/.tree-sitter-cli.loadout.ts";
import { zoxide } from "../../loadouts/private_dot_config/.zoxide.loadout.ts";
import { btop } from "../../loadouts/private_dot_config/btop/.btop.loadout.ts";
import { fzf } from "../../loadouts/private_dot_config/fzf/.fzf.loadout.ts";
import { yazi } from "../../loadouts/private_dot_config/yazi/.yazi.loadout.ts";
import { setupCompletions, zshPlugins } from "../../loadouts/private_dot_config/zsh/.zsh.loadout.ts";

// What several profiles share. Plain lists, not templates: each profile
// still says which installer moves them. Adding a shell tool is one line
// here, not one per profile.
// The shell tools every Omarchy and macOS machine has.
export const everydayCli = [
  yazi,
  fzf,
  starship,
  atuin,
  bat,
  eza,
  btop,
  fd,
  gitDelta,
  gum,
  lazydocker,
  lazygit,
  ripgrep,
  treeSitterCli,
  zoxide,
];

export const shellScripts = [zshPlugins, setupCompletions];
