# Shortcuts for chezmoi. chezmoi always reads one source, `chezmoi
# source-path` (the main checkout), whatever the current directory, so inside
# a feature worktree of it (workmux, ../chezmoi__worktrees/<feature>) plain
# chezmoi acts on master. There the read-only ones (chzdi, chzapnv) follow the
# worktree with --source, and the ones that change things (chzap, chzad,
# chzup) refuse: a full apply from a worktree leaves its new files in $HOME if
# the feature is abandoned. Elsewhere they run chezmoi as is.

# The root of the feature worktree the current directory is in, or nothing:
# a git checkout other than the source that shares the source's repository.
_chz_worktree() {
  local top common src
  top=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  src=$(command chezmoi source-path 2>/dev/null) || return 0
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
unalias chzdi chzapnv chzap chzad chzup 2>/dev/null

chzdi() { _chz_read diff "$@" }
chzapnv() { _chz_read apply -nv "$@" }
chzap() { _chz_write apply "$@" }
chzad() { _chz_write add "$@" }
chzup() { _chz_write update "$@" }

# Aliases got chezmoi's completion for free; functions need it attached.
(($+functions[compdef])) && compdef _chezmoi chzdi chzapnv chzap chzad chzup 2>/dev/null
