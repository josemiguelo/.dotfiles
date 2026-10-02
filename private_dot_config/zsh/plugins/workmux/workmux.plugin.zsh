(($+commands[workmux])) || return

# Force the tmux backend for every workmux invocation, including
# non-interactive ones that bypass the workmux() function below entirely
# (e.g. galileo.nvim's overseer tasks, which exec workmux directly). Without
# this, workmux auto-detects the backend from $TMUX/$KITTY_WINDOW_ID/etc.,
# and a process with no $TMUX (nvim running directly in a kitty tab, no
# tmux involved at all) gets detected as "kitty" and refuses session mode
# outright -- even though a tmux server is reachable on the default socket
# regardless of what terminal launched the process. Harmless for the
# interactive paths below: they only ever run `workmux add --headless ...`
# (backend-check-exempt) or `command workmux add -s ...` from inside a branch
# that already confirmed $TMUX is set, so this changes nothing for either of
# them.
export WORKMUX_BACKEND=tmux

# `workmux add`/`open` both refuse session mode outside tmux ("Session mode
# ... only supported with tmux"), even though workmux is always used with
# tmux sessions here. Wrap both specifically:
# - open: outside tmux, hand off to tmux-workmux-open (shared with the
#   tmux-attach picker), which bootstraps into tmux to run it.
# - add: outside tmux, do the slow part (checkout, hooks, file ops) headless
#   under a gum spinner first — headless needs no tmux backend at all,
#   sidestepping the error entirely — then hand off the same way.
# Every other subcommand passes straight through.
#
# No `exec` anywhere in here: this function runs in the interactive shell's
# own process (unlike a script, which gets its own disposable one), so
# replacing it would close the terminal once the tmux workflow ends instead
# of returning to the prompt.
workmux() {
  case "$1" in
  open)
    shift
    if [[ -n "$TMUX" ]]; then
      # -s forces session mode; safe even though it's already the configured
      # default, and matches tmux-workmux-open's same defensive choice.
      command workmux open -s "$@"
    else
      "$HOME/.local/bin/tmux-workmux-open" "$@"
    fi
    ;;

  add)
    shift

    if [[ -n "$TMUX" ]]; then
      command workmux add -s "$@"
      return
    fi

    # gum runs its arguments as a program, so the binary's own path: `command`
    # is a shell builtin, not a program gum can start.
    local json
    json=$(gum spin --title "Creating worktree..." --show-error -- "$(whence -p workmux)" add --headless --json "$@")
    local rc=$?
    # gum 2 asks the terminal about display modes as it exits and doesn't wait
    # for the answers; drop them before they reach the prompt or, on success,
    # get typed into the new tmux session.
    if [[ -t 0 ]]; then
      local _reply
      while read -s -t 0.05 -k 1 _reply; do :; done
    fi
    ((rc == 0)) || return $rc

    local handle
    handle=$(print -r -- "$json" | command jq -r '.handle // empty')
    if [[ -z "$handle" ]]; then
      print -u2 "workmux: couldn't determine the created worktree's handle from: $json"
      return 1
    fi

    "$HOME/.local/bin/tmux-workmux-open" "$handle"
    ;;

  *)
    command workmux "$@"
    ;;
  esac
}
