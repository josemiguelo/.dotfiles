import { atuin } from "../../loadouts/atuin/atuin.loadout.ts";
import { bat } from "../../loadouts/bat/bat.loadout.ts";
import { eza } from "../../loadouts/eza/eza.loadout.ts";
import { fd } from "../../loadouts/fd/fd.loadout.ts";
import { gitDelta } from "../../loadouts/git-delta/git-delta.loadout.ts";
import { gum } from "../../loadouts/gum/gum.loadout.ts";
import { lazydocker } from "../../loadouts/lazydocker/lazydocker.loadout.ts";
import { lazygit } from "../../loadouts/lazygit/lazygit.loadout.ts";
import { ripgrep } from "../../loadouts/ripgrep/ripgrep.loadout.ts";
import { starship } from "../../loadouts/starship/starship.loadout.ts";
import { treeSitterCli } from "../../loadouts/tree-sitter-cli/tree-sitter-cli.loadout.ts";
import { zoxide } from "../../loadouts/zoxide/zoxide.loadout.ts";
import { btop } from "../../loadouts/btop/btop.loadout.ts";
import { fzf } from "../../loadouts/fzf/fzf.loadout.ts";
import { yazi } from "../../loadouts/yazi/yazi.loadout.ts";
import { setupCompletions, zshPlugins } from "../../loadouts/zsh/zsh.loadout.ts";

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
