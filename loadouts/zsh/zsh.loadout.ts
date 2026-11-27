// zsh: the shell, its plugins and completions, and the login shell. Its
// dotfiles are home/: ~/.config/zsh, and ~/.zshenv, which points ZDOTDIR there.
import { program, script, withOmarchy } from "loadout";

// macOS ships zsh, so only Linux machines map it.
export const zsh = program("zsh", { canBeInstalled: [withOmarchy] });

// antidote and the bundles .zplugins declares, present as clones; and
// whether the antidote clone and its bundles are behind their GitHub tips.
export const zshPlugins = script("zsh-plugins", {
  description: "antidote and the bundles .zplugins declares",
  module: () => import("./.loadout/plugins.ts"),
  runAfter: [zsh],
  updates: {
    antidote: () => import("./.loadout/outdated-antidote.ts"),
    "antidote-plugins": () => import("./.loadout/outdated-antidote-plugins.ts"),
  },
});

export const setupCompletions = script("setup-completions", { description: "shell completions", module: () => import("./.loadout/completions.ts") });

// Flips only once zsh and ~/.zshenv are in place, so the first zsh login is
// never a bare one. Next login.
export const defaultShell = script("default-shell", {
  description: "login shell set to zsh",
  module: () => import("./.loadout/default-shell.ts"),
  needsSudo: true,
  runAfter: [zsh],
});
