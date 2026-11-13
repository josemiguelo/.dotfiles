// josemiguelo's repos, cloned where start-dotfiles-change's sessions expect them.
import { script } from "loadout";
import { git } from "../.gitconfig/.git.loadout.ts";
import { onepasswordCli } from "../private_dot_config/.1password/.1password.loadout.ts";
import { cmocka, jsonC, meson, ninja } from "../private_dot_config/.omarchy-iso-test.loadout.ts";

// Bare clones with their default branch's worktree, named by the machine:
// `args(bareRepos, "loadout", "loadout.wiki")`.
export const bareRepos = script("bare-repos", {
  description: "josemiguelo's repos as bare clones in ~/Repos/gh/josemiguelo",
  managedBy: ".loadout/bare-repos.ts",
  runAfter: [git],
});

// The KaiT2en -> Omarchy work (docs/t2-macbook.md), on top of bare-repos'
// t2-arch-packages, omarchy and omarchy-iso: the forks' T2 worktrees (omarchy's
// t2-kait2en-stable, omarchy-iso's t2-kait2en)
// and upstream remotes, KaiT2en and omarchy-pkgs, libvfio-user built, the
// package signing key from 1Password, and kait2en-sync's daily timer.
export const kait2enDev = script("kait2en-dev", {
  description: "KaiT2en -> Omarchy development: forks, clones, signing key, daily kait2en-sync",
  managedBy: ".loadout/kait2en-dev.ts",
  runAfter: [bareRepos, onepasswordCli, meson, ninja, jsonC, cmocka],
});
