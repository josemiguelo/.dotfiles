# Shortcuts for chezmoi. chezmoi always reads one source, `chezmoi
# source-path` (the main checkout), whatever the current directory, so inside
# a feature worktree of it (workmux, ../chezmoi__worktrees/<feature>) plain
# chezmoi acts on master. There the read-only ones (chzdi, chzapnv) follow the
# worktree with --source, and the ones that change things (chzap, chzad,
# chzup) refuse: a full apply from a worktree leaves its new files in $HOME if
# the feature is abandoned. Elsewhere they run chezmoi as is. chztry runs a
# program on the worktree's configs, without applying anything to $HOME.

# The root of the feature worktree the current directory is in, or nothing:
# a git checkout other than the source that shares the source's repository.
# source-path is the repo's .chezmoiroot folder, not its top.
_chz_worktree() {
  local top common src
  top=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  src=$(command chezmoi source-path 2>/dev/null) || return 0
  src=$(git -C "$src" rev-parse --show-toplevel 2>/dev/null) || return 0
  [[ ${top:A} == ${src:A} ]] && return 0
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 0
  [[ ${common:A} == ${src:A}/.git ]] && print -r -- "$top"
  return 0
}

# Runs chezmoi with the worktree as its source when inside one.
_chz_read() {
  local wt=$(_chz_worktree)
  if [[ -n $wt ]]; then
    command chezmoi --source "$wt" "$@"
  else
    command chezmoi "$@"
  fi
}

# Runs chezmoi, or refuses inside a feature worktree.
_chz_write() {
  local wt=$(_chz_worktree)
  if [[ -n $wt ]]; then
    print -u2 -r -- "chezmoi $1 would act on master, not this worktree ($wt)."
    print -u2 -r -- "Apply only what you're testing: chezmoi --source \"$wt\" apply <target>..."
    return 1
  fi
  command chezmoi "$@"
}

# A shell that had these as aliases would expand them while defining these.
unalias chzdi chzapnv chzap chzad chzup chztry 2>/dev/null

chzdi() { _chz_read diff "$@" }
chzapnv() { _chz_read apply -nv "$@" }
chzap() { _chz_write apply "$@" }
chzad() { _chz_write add "$@" }
chzup() { _chz_write update "$@" }

# chztry <program> [args...]: renders the worktree into a preview home (all
# of it, but no scripts or externals: nothing runs, nothing downloads) and
# runs the program with its configs from there: ~/.config through
# XDG_CONFIG_HOME, zsh through ZDOTDIR, starship through STARSHIP_CONFIG, the
# worktree's ~/.local/bin first on PATH. Everything started from it (a shell
# in nvim, panes in tmux) inherits that. tmux gets its own server, so the
# preview config isn't read by the server you're in. Data, state and caches
# stay the real ones (nvim's plugins aren't reinstalled). Each call
# re-renders from scratch, so files removed in the worktree are gone too.
chztry() {
  if (( ! $# )); then
    print -u2 -r -- "usage: chztry <program> [args...]  (inside a feature worktree)"
    return 2
  fi
  local wt=$(_chz_worktree)
  if [[ -z $wt ]]; then
    print -u2 -r -- "chztry: not in a feature worktree of the chezmoi source."
    return 1
  fi
  # In memory where there's a runtime dir (tmpfs): chezmoi syncs every file
  # and state write to disk, which on btrfs turns 0.1s into 10s.
  local root=${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/chztry
  local preview=$root/${wt:t}
  command rm -rf -- "$preview"
  mkdir -p -- "$preview" || return
  command chezmoi --source "$wt" --destination "$preview" \
    --persistent-state "$preview.boltdb" \
    apply --force --exclude scripts,externals || return
  local -a cmd=("$@")
  [[ $1 == tmux ]] && cmd=(env -u TMUX tmux -L "chztry-${wt:t}" "${@:2}")
  env XDG_CONFIG_HOME="$preview/.config" \
    ZDOTDIR="$preview/.config/zsh" \
    STARSHIP_CONFIG="$preview/.config/starship.toml" \
    PATH="$preview/.local/bin:$PATH" \
    "${cmd[@]}"
}

# Aliases got chezmoi's completion for free; functions need it attached.
(($+functions[compdef])) && compdef _chezmoi chzdi chzapnv chzap chzad chzup 2>/dev/null
(($+functions[compdef])) && compdef _precommand chztry 2>/dev/null
