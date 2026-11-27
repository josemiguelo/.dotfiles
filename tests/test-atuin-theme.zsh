#!/usr/bin/env zsh
# Tests loadouts/atuin/home/private_dot_config/atuin/theme.zsh: which theme the search gets
# for each answer of appearance-is-dark, that it's read again at every search,
# and that the theme exists. Run: tests/test-atuin-theme.zsh
emulate -L zsh
DIR=${0:A:h:h}/loadouts/atuin/home/private_dot_config/atuin
WORK=$(mktemp -d)
trap 'rm -rf -- "${WORK:?}"' EXIT
export HOME=$WORK
path=(/usr/bin /bin)
unset XDG_CONFIG_HOME
integer fail=0
eq() { if [[ $1 == $2 ]]; then print "  ok - $3"; else print "  FAIL - $3 (expected [$2], got [$1])"; fail+=1; fi }

# Prints what a child process (atuin) would see, and the arguments.
_atuin_search() { sh -c 'echo "$ATUIN_THEME__NAME $ATUIN_THEME_DIR $*"' _ "$@" }
source $DIR/theme.zsh
appearance() { mkdir -p $HOME/.local/bin; print "#!/bin/sh\nexit $1" >| $HOME/.local/bin/appearance-is-dark; chmod +x $HOME/.local/bin/appearance-is-dark }

rest="$HOME/.config/atuin/themes --keymap-mode=vim-insert"
eq "$(_atuin_search --keymap-mode=vim-insert)" "tokyonight-storm $rest" "no appearance-is-dark: dark"
appearance 1
eq "$(_atuin_search --keymap-mode=vim-insert)" "tokyonight-day $rest" "light"
appearance 0
eq "$(_atuin_search --keymap-mode=vim-insert)" "tokyonight-storm $rest" "dark again, same shell"
_atuin_search >/dev/null
eq "${ATUIN_THEME__NAME-unset}" unset "nothing left in the shell"
for t in tokyonight-storm tokyonight-day; do
  [[ -r $DIR/themes/$t.toml ]]; eq $? 0 "$t exists"
done
exit $(( fail > 0 ))
