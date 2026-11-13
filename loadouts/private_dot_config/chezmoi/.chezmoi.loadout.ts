// chezmoi: the dotfiles manager and its checkout (this repo). loadout
// applies the dotfiles itself; these scripts watch the checkout's git side.
import { brew, omarchy, program, script } from "loadout";

export const chezmoi = program("chezmoi", { install: [brew, omarchy] });

export const dotfilesCheckout = "$HOME/.local/share/chezmoi";

export const dotfilesHttps = "https://github.com/josemiguelo/.dotfiles.git";

export const dotfilesSsh = "git@github.com:josemiguelo/.dotfiles.git";

// The dotfiles checkout's git side: `run: [dotfilesPull]`.

// Pulls over https, pushes over ssh: the repo is public, so pulling works
// before GitHub knows this machine's key (github-ssh-key).
export const dotfilesSshRemote = script("dotfiles-ssh-remote", {
  description: "point the chezmoi checkout's pushes at the ssh dotfiles remote",
  run: [
    `git -C ${dotfilesCheckout} remote set-url origin ${dotfilesHttps}`,
    `git -C ${dotfilesCheckout} config remote.origin.pushurl ${dotfilesSsh}`,
  ],
  check: [
    `test "$(git -C ${dotfilesCheckout} config --get remote.origin.url)" = ${dotfilesHttps}`,
    `test "$(git -C ${dotfilesCheckout} config --get remote.origin.pushurl)" = ${dotfilesSsh}`,
  ],
});

// Is the local source behind origin? (throttled fetch, fail-soft offline).
// Converge = pull only.
export const dotfilesPull = script("dotfiles-pull", {
  description: "pull dotfiles source when behind its origin",
  managedBy: ".loadout/pull.ts",
  maintainOnly: true,
});

// Local edits origin hasn't seen. After the pull, so one run rebases before it
// pushes.
export const dotfilesPush = script("dotfiles-push", {
  description: "push dotfiles source when ahead of its origin",
  managedBy: ".loadout/push.ts",
  runAfter: [dotfilesPull],
  maintainOnly: true,
});

// What every machine runs for its dotfiles checkout: `run: [dotfilesAll]`.
export const dotfilesAll = [dotfilesPull, dotfilesPush, dotfilesSshRemote];
