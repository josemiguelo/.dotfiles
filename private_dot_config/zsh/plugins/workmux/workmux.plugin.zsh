(( $+commands[workmux] )) || return

# `workmux add` refuses to create a session-mode worktree outside tmux
# ("Session mode ... only supported with tmux"), even though workmux is
# always used with tmux sessions here. Wrap `add` specifically: do the slow
# part (checkout, hooks, file ops) headless under a gum spinner — headless
# needs no tmux backend at all, sidestepping the error entirely — then hand
# off to tmux-workmux-open (shared with the tmux-attach picker) for the
# actual session attach. Every other subcommand passes straight through.
#
# No `exec` anywhere in here: this function runs in the interactive shell's
# own process (unlike a script, which gets its own disposable one), so
# replacing it would close the terminal once the tmux workflow ends instead
# of returning to the prompt.
workmux() {
  if [[ "$1" != "add" ]]; then
    command workmux "$@"
    return
  fi
  shift

  if [[ -n "$TMUX" ]]; then
    # -s forces session mode; safe even though it's already the configured
    # default, and matches tmux-workmux-open's same defensive choice.
    command workmux add -s "$@"
    return
  fi

  local json
  json=$(gum spin --title "Creating worktree..." --show-error -- command workmux add --headless --json "$@")
  local rc=$?
  (( rc == 0 )) || return $rc

  local handle
  handle=$(print -r -- "$json" | command jq -r '.handle // empty')
  if [[ -z "$handle" ]]; then
    print -u2 "workmux: couldn't determine the created worktree's handle from: $json"
    return 1
  fi

  "$HOME/.local/bin/tmux-workmux-open" "$handle"
}
