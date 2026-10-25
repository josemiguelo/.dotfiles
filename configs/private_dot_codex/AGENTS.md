# This machine

omalauncher-galaxy-a56: Arch inside the omalauncher Android launcher, set up by
[loadout](https://github.com/josemiguelo/loadout) from the dotfiles in
~/.local/share/chezmoi, where everything on it is tracked. Its rules come
before the launcher's own instructions where they differ:

- The launcher's files (~/.config/omalauncher: widgets, style, layout): follow
  ~/.config/omalauncher/widgets/AGENTS.md. A widget's packages go in its
  `requires`, installed with `loadout run omalauncher-requires`, not `pacman -S`.
- Anything else you install or set up becomes a loadout program, script or
  config: read ~/.local/share/chezmoi/AGENTS.md (its "omalauncher" section) first.
- Never commit or push the dotfiles unless the user asks, in that turn.
