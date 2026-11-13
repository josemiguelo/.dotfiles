// zsh: the shell, its plugins and completions, and the login shell. Its
// dotfiles are this directory plus ~/.zshenv, which points ZDOTDIR here.
import { omarchy, program, runScript, script } from "loadout";

// macOS ships zsh, so only Linux machines map it.
export const zsh = program("zsh", { install: [omarchy] });

// antidote and the bundles .zplugins declares, present as clones; and
// whether the antidote clone and its bundles are behind their GitHub tips.
export const zshPlugins = script("zsh-plugins", {
  description: "antidote and the bundles .zplugins declares",
  managedBy: ".loadout/plugins.ts",
  runAfter: [zsh],
  outdated: [
    {
      name: "antidote",
      command: runScript(".loadout/outdated-antidote.ts"),
      upgrade: runScript(".loadout/outdated-antidote.ts update {item}"),
    },
    {
      name: "antidote-plugins",
      command: runScript(".loadout/outdated-antidote-plugins.ts"),
      upgrade: runScript(".loadout/outdated-antidote-plugins.ts update {item}"),
    },
  ],
});

export const setupCompletions = script("setup-completions", { description: "shell completions", managedBy: ".loadout/completions.ts" });

// Flips only once zsh and ~/.zshenv are in place, so the first zsh login is
// never a bare one. Next login.
export const defaultShell = script("default-shell", {
  description: "login shell set to zsh",
  managedBy: ".loadout/default-shell.ts",
  needsSudo: true,
  runAfter: [zsh],
});
