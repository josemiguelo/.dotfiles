# try, set up the way Omarchy does for bash (default/bash/init): `try init`
# defines the try function that can cd this shell into ~/Work/tries/…, loaded
# the first time try runs so every shell doesn't start ruby. try's picker has
# fixed colors made for dark terminals (lib/tui.rb's 256-color palette: a
# dark grey selection bar, bright yellow matches) and no theme setting, so on
# a light desktop (appearance-is-dark) it runs with NO_COLOR: plain text, the
# selected row still marked with →.
if (( $+commands[try] )); then
  try() {
    unfunction try
    eval "$(SHELL=${commands[zsh]:-zsh} command try init ~/Work/tries)"
    # Keep try init's function, and put the color choice in front of it.
    functions[_try_init]=$functions[try]
    try() {
      if (( $+commands[appearance-is-dark] )) && ! appearance-is-dark; then
        local -x NO_COLOR=1
      fi
      _try_init "$@"
    }
    try "$@"
  }
fi

# start-loadout [query]: a try session that knows it may touch the
# interconnected loadout/loadouts/chezmoi/skills ecosystem. ~/Work holds
# anything, not just this, so plain `try` stays untouched -- this copies
# (not links: a try folder is ephemeral/self-contained, not meant to
# track loadouts live) the "repo-ecosystem" skill from loadouts into
# THIS session's local .claude/skills/, only when called through this
# specific function.
start-loadout() {
  emulate -L zsh
  try "$@"
  local source="$HOME/.config/loadouts/repo-ecosystem"
  local dest=".claude/skills/repo-ecosystem"
  if [[ ! -d $source ]]; then
    print -u2 "start-loadout: $source not found -- is loadouts cloned?"
    return 1
  fi
  [[ -e $dest ]] && return 0
  mkdir -p .claude/skills
  cp -r "$source" "$dest"
}
