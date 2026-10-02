# gclone <url> [--bare] [git clone options]: clone a repo into
# ~/Repos/<host>/<owner>/<repo> and cd into it, from nothing but its URL
# (https or ssh).
#
#   git@github.com:ai-hero-dev/ai-coding-crash-course.git
#     -> ~/Repos/gh/ai-hero-dev/ai-coding-crash-course
#
# Hosts get a short name (github.com gh, gitlab.com gl, bitbucket.org bb,
# codeberg.org cb, git.sr.ht srht); any other host keeps its own name, with a
# warning. Only the last two path segments are kept, so a GitLab subgroup
# (gitlab.com/group/sub/repo) lands in gl/sub/repo, and a URL copied from the
# browser (…/owner/repo/tree/main/src) still finds owner/repo. The URL is
# cloned exactly as given: https stays https, ssh stays ssh.
#
# --bare clones bare into that same path and adds a worktree for the
# default branch under all_worktrees/<branch> (the layout workmux expects),
# cd'ing into the worktree rather than the bare root. Without --bare, gum
# asks whether to clone bare; answering no falls back to a plain clone. The
# fetch refspec (remote.origin.fetch) is set explicitly on every bare clone,
# since `git clone --bare` otherwise leaves it unconfigured and a later
# `git fetch` silently fetches nothing.
#
# An existing folder is never touched: a clone of the same repo (compared by
# host/owner/repo, whatever the URL form; bare repos too) offers to cd there,
# a different repo or a non-repo folder is an error. A failed clone leaves
# nothing behind. Everything is printed through gum.

(( $+commands[git] )) || return

typeset -gA _GCLONE_HOSTS=(
  github.com gh
  gitlab.com gl
  bitbucket.org bb
  codeberg.org cb
  git.sr.ht srht
)

# _gclone_parse <url>: set reply=(host short owner repo); fail on a URL that
# isn't a repo URL. short is the host's short name, or the host itself.
_gclone_parse() {
  emulate -L zsh -o extended_glob
  # Not "path": zsh ties that array to $PATH.
  local url=$1 rest host rpath
  local -a parts

  if [[ $url == *://* ]]; then
    # scheme://[user@]host[:port]/path
    rest=${url#*://}
    host=${rest%%/*}
    [[ $rest == */* ]] || return 1
    rpath=${rest#*/}
    host=${host##*@}
    host=${host%%:*}
  elif [[ $url == [^/]##:* ]]; then
    # scp-style [user@]host:path
    host=${${url%%:*}##*@}
    rpath=${url#*:}
  else
    return 1
  fi

  host=${${host:l}#www.}
  [[ -n $host ]] || return 1

  rpath=${rpath%%[?#]*}
  rpath=${rpath##/##}
  rpath=${rpath%%/##}
  # A GitLab page URL separates the project from the page with /-/.
  rpath=${rpath%%/-/*}
  parts=( ${(s:/:)rpath} )
  # Hosts whose project paths are always owner/repo: whatever follows is a
  # browser page (tree/main/src, blob/..., src/..., pull/1).
  case $host in
    github.com|bitbucket.org|codeberg.org|git.sr.ht) parts=( ${parts[1,2]} ) ;;
  esac
  (( ${#parts} >= 2 )) || return 1
  parts=( ${parts[-2,-1]} )
  parts[2]=${parts[2]%.git}
  parts[1]=${parts[1]#\~}
  local p
  for p in $parts; do
    [[ -n $p && $p != . && $p != .. ]] || return 1
  done

  reply=( $host ${_GCLONE_HOSTS[$host]:-$host} ${parts[1]} ${parts[2]} )
}

# The same repo, whatever the URL form: host/owner/repo, case-insensitive.
_gclone_identity() {
  emulate -L zsh
  local -a reply
  _gclone_parse "$1" || return 1
  print -r -- "${(L)reply[1]}/${(L)reply[3]}/${(L)reply[4]}"
}

# _gclone_cleanup <target> <created>: remove a failed clone's empty parent
# dirs, up to (and including) the first one this clone created.
_gclone_cleanup() {
  emulate -L zsh
  local target=$1 created=$2
  [[ -n $created ]] || return 0
  local dir=${target:h}
  while [[ $dir == $created* && -d $dir ]] && rmdir "$dir" 2>/dev/null; do
    dir=${dir:h}
  done
}

gclone() {
  emulate -L zsh -o extended_glob

  if (( ! $+commands[gum] )); then
    print -u2 "gclone: needs gum (https://github.com/charmbracelet/gum)"
    return 1
  fi

  if (( $# == 0 )) || [[ $1 == (-h|--help) ]]; then
    gum style --border rounded --padding "0 1" \
      "$(gum style --bold 'gclone <url> [--bare] [git clone options]')" \
      "" \
      "Clones into ~/Repos/<host>/<owner>/<repo> and cds into it." \
      "https and ssh URLs; gh gl bb cb srht, other hosts by name." \
      "" \
      "--bare clones bare and adds a worktree under all_worktrees/<branch>." \
      "Without it, gum asks whether to clone bare."
    return $(( $# == 0 ))
  fi

  local url=$1
  shift

  local bare=
  local -a rest a
  for a in "$@"; do
    if [[ $a == --bare ]]; then
      bare=1
    else
      rest+=("$a")
    fi
  done
  set -- "${rest[@]}"

  local -a reply
  if ! _gclone_parse "$url"; then
    gum log --level error "Not a repository URL:" url "$url"
    return 1
  fi
  local host=$reply[1] short=$reply[2] owner=$reply[3] repo=$reply[4]
  local root=$HOME/Repos
  local target=$root/$short/$owner/$repo

  if [[ -z ${_GCLONE_HOSTS[$host]} ]]; then
    gum log --level warn "Unknown host, using its name as the folder:" host "$host"
  fi

  if [[ -e $target ]]; then
    if git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
      # The URL as configured: `remote get-url` applies url.*.insteadOf
      # rewrites, which can turn it into something that no longer names the repo.
      local existing
      existing=$(git -C "$target" config --get remote.origin.url 2>/dev/null)
      if [[ -n $existing ]] && [[ "$(_gclone_identity "$existing")" == "$(_gclone_identity "$url")" ]]; then
        gum log --level info "Already cloned:" path "${target/#$HOME/~}"

        if [[ "$(git -C "$target" rev-parse --is-bare-repository 2>/dev/null)" == true ]]; then
          # A bare repo has no files of its own to cd into; offer its
          # worktrees instead (excluding the bare entry itself, which
          # `worktree list` always lists first, with a "bare" line instead
          # of HEAD/branch).
          local -a lines worktrees
          lines=(${(f)"$(git -C "$target" worktree list --porcelain)"})
          local wt= is_bare= line
          for line in $lines; do
            if [[ $line == worktree\ * ]]; then
              [[ -n $wt && -z $is_bare ]] && worktrees+=("$wt")
              wt=${line#worktree }
              is_bare=
            elif [[ $line == bare ]]; then
              is_bare=1
            fi
          done
          [[ -n $wt && -z $is_bare ]] && worktrees+=("$wt")

          if (( ${#worktrees} == 1 )); then
            gum confirm "cd into ${worktrees[1]/#$HOME/~}?" && cd "$worktrees[1]"
          elif (( ${#worktrees} > 1 )); then
            local chosen
            chosen=$(printf '%s\n' "${worktrees[@]/#$HOME/~}" | gum choose --header "cd into which worktree?")
            [[ -n $chosen ]] && cd "${chosen/#\~/$HOME}"
          else
            gum confirm "cd into ${target/#$HOME/~}?" && cd "$target"
          fi
          return 0
        fi

        if gum confirm "cd into ${target/#$HOME/~}?"; then
          cd "$target"
        fi
        return 0
      fi
      gum log --level error "Another repo is already there:" path "${target/#$HOME/~}" origin "${existing:-none}"
      return 1
    fi
    if [[ -n $(print -rl -- "$target"/*(DN[1])) ]]; then
      gum log --level error "Folder exists and isn't a git repo:" path "${target/#$HOME/~}"
      return 1
    fi
  fi

  if [[ -z $bare ]]; then
    gum confirm "Clone $owner/$repo as a bare repo + worktree?" && bare=1
  fi

  # The first folder this clone creates, so a failed clone can remove what it
  # made (only while empty: other repos may have landed there meanwhile).
  local created=$target
  while [[ ! -e ${created:h} ]]; do created=${created:h}; done
  [[ -e $created ]] && created=
  mkdir -p "${target:h}" || return 1

  # The spinner hides the terminal, so git and ssh must not stop to ask for a
  # password or an unknown host key: they fail instead, and --show-error
  # prints git's own message.
  if [[ -n $bare ]]; then
    if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes" \
      gum spin --show-error --title "Cloning $owner/$repo (bare)…" -- git clone --bare "$@" -- "$url" "$target"; then
      gum log --level error "git clone --bare failed:" url "$url"
      _gclone_cleanup "$target" "$created"
      return 1
    fi

    # `git clone --bare` mirrors refs/heads/* from the remote into the bare
    # repo's own refs/heads/* once, but -- unlike a plain clone -- leaves
    # remote.origin.fetch unset, so a later `git fetch`/`git fetch origin`
    # has no refspec and silently fetches nothing.
    git -C "$target" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git -C "$target" fetch --prune origin >/dev/null 2>&1

    local default_branch
    default_branch=$(git -C "$target" symbolic-ref --quiet --short HEAD)
    if [[ -z $default_branch ]]; then
      gum log --level error "Couldn't determine the default branch:" path "${target/#$HOME/~}"
      rm -rf -- "$target"
      _gclone_cleanup "$target" "$created"
      return 1
    fi

    local worktree=$target/all_worktrees/$default_branch
    if ! git -C "$target" worktree add "$worktree" "$default_branch" >/dev/null 2>&1; then
      gum log --level error "Couldn't add the initial worktree:" branch "$default_branch"
      cd "$target"
      return 0
    fi
    # Not set by `worktree add` on its own: the branch exists locally from
    # the bare clone itself, not from a fetch that would have wired tracking up.
    git -C "$worktree" branch --quiet --set-upstream-to="origin/$default_branch" "$default_branch" >/dev/null 2>&1

    cd "$worktree"
    gum log --level info "Cloned bare:" path "${target/#$HOME/~}" worktree "${worktree/#$HOME/~}"
    return 0
  fi

  if GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes" \
    gum spin --show-error --title "Cloning $owner/$repo…" -- git clone "$@" -- "$url" "$target"; then
    cd "$target"
    gum log --level info "Cloned:" path "${target/#$HOME/~}"
    return 0
  fi

  gum log --level error "git clone failed:" url "$url"
  _gclone_cleanup "$target" "$created"
  return 1
}
