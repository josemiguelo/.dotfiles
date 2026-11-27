(($+commands[gum])) || return

# gum 2's interactive commands ask the terminal about display modes as they
# exit (DECRQM 2026/2027) and don't wait for the answers, which then land on
# the prompt as `2026;2$y2027;0$y`, or get typed into whatever reads the
# terminal next. Every gum call from a zsh function goes through here: the
# real gum runs, then the answers already waiting are dropped (only on a
# terminal, only after the commands that query). Exit status and output are
# gum's.
gum() {
  command gum "$@"
  local rc=$?
  case $1 in
  spin | confirm | choose | input | filter | write | file | pager | table)
    if [[ -t 0 ]]; then
      local _reply
      while read -s -t 0.05 -k 1 _reply; do :; done
    fi
    ;;
  esac
  return $rc
}
