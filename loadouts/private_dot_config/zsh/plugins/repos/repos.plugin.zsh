# gclone [git clone options] <url> [<dir>]: git clone, plus a home for the
# repo. Every argument goes to git clone as given, in any order; gclone only
# reads them the way git does, to find the URL and the flags it adds to.
#
# Without a <dir>, the repo lands in ~/Repos/<host>/<owner>/<repo>, from
# nothing but its URL (https or ssh), and gclone cds into it.
#
#   git@github.com:ai-hero-dev/ai-coding-crash-course.git
#     -> ~/Repos/gh/ai-hero-dev/ai-coding-crash-course
#
# Hosts get a short name (github.com gh, gitlab.com gl, bitbucket.org bb,
# codeberg.org cb, git.sr.ht srht); any other host keeps its own name, with a
# warning. Only the last two path segments are kept, so a GitLab subgroup
# (gitlab.com/group/sub/repo) lands in gl/sub/repo, and a URL copied from the
# browser (…/owner/repo/tree/main/src) still finds owner/repo. A <dir> is
# honoured as git honours it, and everything below applies to it instead.
#
# --bare also adds a worktree for the default branch under
# all_worktrees/<branch> (the layout workmux expects), cd'ing into the
# worktree rather than the bare root, and sets the fetch refspec
# (remote.<name>.fetch), which `git clone --bare` leaves unconfigured so that
# a later `git fetch` silently fetches nothing; with --single-branch (or
# --depth, which implies it) the refspec covers only that branch. Without
# --bare, gum asks whether to clone bare, and yes means --bare. --mirror is
# passed through with none of that: no question, no refspec (a mirror has its
# own), no worktree (its fetches would overwrite the checked-out branch).
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

# git clone's long options come from git itself (--git-completion-helper-all,
# hidden ones too), so they can't go stale. Its short options that take a
# value aren't listed there: these come from `git clone -h`, and
# tests/test-repos-plugin.zsh fails when that changes.
typeset -g _GCLONE_VALUE_SHORT=jobuc
# Aliases git lists as options of their own: a shortened name matching both
# an option and its alias isn't ambiguous to git, so it isn't to gclone.
typeset -gA _GCLONE_ALIASES=(
  --naked --bare
  --no-naked --no-bare
  --recursive --recurse-submodules
  --no-recursive --no-recurse-submodules
)

# _gclone_args <git clone args>: read them the way git clone does, shortened
# long options included (--dep is --depth). Sets the caller's positional (the
# URL, then the folder if given), bare, mirror, single (only one branch is
# cloned) and help; the last of --x/--no-x wins. Fails on an option git would
# reject as unknown or ambiguous.
_gclone_args() {
  emulate -L zsh
  local a i o n name narrow= wide=
  local -a found
  # Each long option, alias or not, mapped to the option it is, with a
  # trailing = if it takes a value.
  local -A canon
  for o in ${=$(git clone --git-completion-helper-all 2>/dev/null)}; do
    [[ $o == -- ]] && continue
    n=${o%=}
    canon[$n]=${_GCLONE_ALIASES[$n]:-$n}${o#$n}
  done

  positional=() bare= mirror= single= help=
  while (( $# )); do
    a=$1
    shift
    case $a in
      --) positional+=("$@"); break ;;
      -h|--help) help=1; continue ;;
      --?*)
        name=${a%%=*}
        if (( $+canon[$name] )); then
          o=$canon[$name]
        else
          found=()
          for n in ${(k)canon}; do
            [[ $n == $name* ]] && found+=($canon[$n])
          done
          found=(${(u)found})
          if (( ${#found} != 1 )); then
            if (( ${#found} )); then
              found=(${found%=})
              gum log --level error -- "Ambiguous git clone option:" option "$name" "could be" "${(oj:, :)found}"
            else
              gum log --level error -- "Unknown git clone option:" option "$name"
            fi
            return 1
          fi
          o=$found[1]
        fi
        # Its value is the next argument unless it came with =.
        [[ $o == *= && $a != *=* ]] && (( $# )) && shift
        case $o in
          --bare) bare=1 ;;
          --no-bare) bare= ;;
          --mirror) mirror=1 ;;
          --no-mirror) mirror= ;;
          --single-branch) single=1 wide= ;;
          --no-single-branch) single= wide=1 ;;
          --depth=|--shallow-since=|--shallow-exclude=) narrow=1 ;;
        esac ;;
      -?*)
        # A bundle of short flags (-qb main, -bmain): a letter that takes a
        # value takes the rest of the bundle, or the next argument.
        for (( i = 2; i <= ${#a}; i++ )); do
          if [[ $_GCLONE_VALUE_SHORT == *${a[i]}* ]]; then
            (( i == ${#a} && $# )) && shift
            break
          fi
        done ;;
      *) positional+=("$a") ;;
    esac
  done
  # --depth and the other shallow options imply --single-branch.
  [[ -n $narrow && -z $wide ]] && single=1
  return 0
}

# Every gum call below ends its own flags with --: gum would take a URL or
# path starting with -- for one of its flags and print its help instead.
gclone() {
  emulate -L zsh -o extended_glob

  if (( ! $+commands[gum] )); then
    print -u2 "gclone: needs gum (https://github.com/charmbracelet/gum)"
    return 1
  fi

  local -a positional
  local bare mirror single help
  _gclone_args "$@" || return 1

  if (( $# == 0 )) || [[ -n $help ]]; then
    gum style --border rounded --padding "0 1" -- \
      "$(gum style --bold -- 'gclone [git clone options] <url> [<dir>]')" \
      "" \
      "git clone, landing in ~/Repos/<host>/<owner>/<repo> and cd'ing there." \
      "  gclone git@github.com:owner/repo.git  ->  ~/Repos/gh/owner/repo" \
      "Every option goes to git clone, in any order (git clone -h lists" \
      "them); a <dir> is honoured as git honours it." \
      "" \
      "$(gum style --bold -- URLs)" \
      "  https, ssh:// and git@host:owner/repo, cloned exactly as given." \
      "  Browser URLs work too: …/owner/repo/tree/main/src, …/-/blob/…" \
      "  Only the last two path segments are kept (GitLab group/sub/repo" \
      "  lands in gl/sub/repo)." \
      "  Host folders: github.com gh, gitlab.com gl, bitbucket.org bb," \
      "  codeberg.org cb, git.sr.ht srht." \
      "  Any other host keeps its own name, with a warning." \
      "" \
      "$(gum style --bold -- 'What it adds to git clone')" \
      "  --bare      Also adds a worktree for the default branch under" \
      "              all_worktrees/<branch> (workmux's layout), cds into" \
      "              it, and sets the fetch refspec bare clones lack." \
      "  no --bare   gum asks whether to clone bare; yes means --bare." \
      "  --mirror    Nothing: no question, no worktree, no refspec." \
      "  -h, --help  Show this help." \
      "" \
      "$(gum style --bold -- 'Already there')" \
      "  The same repo (any URL form, bare too): offers to cd into it, or" \
      "  into one of its worktrees. Another repo, or a folder with files" \
      "  that isn't a repo: an error, and it's left alone." \
      "" \
      "$(gum style --bold -- Failures)" \
      "  git never stops to ask for a password or a host key: the clone" \
      "  fails and prints git's error, leaving no folders behind."
    return $(( $# == 0 ))
  fi

  local url=$positional[1]
  local -a reply
  if [[ -z $url ]] || ! _gclone_parse "$url"; then
    gum log --level error -- "Not a repository URL:" url "${url:-none}"
    return 1
  fi
  local host=$reply[1] short=$reply[2] owner=$reply[3] repo=$reply[4]
  local target
  if (( ${#positional} > 1 )); then
    target=${positional[2]:a}
  else
    target=$HOME/Repos/$short/$owner/$repo
    if [[ -z ${_GCLONE_HOSTS[$host]} ]]; then
      gum log --level warn -- "Unknown host, using its name as the folder:" host "$host"
    fi
  fi

  if [[ -e $target ]]; then
    if git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
      # The URLs as configured: `remote get-url` applies url.*.insteadOf
      # rewrites, which can turn one into something that no longer names the
      # repo. Any remote counts, since --origin may have named it otherwise.
      local r existing= same=
      for r in ${(f)"$(git -C "$target" remote 2>/dev/null)"}; do
        existing=$(git -C "$target" config --get "remote.$r.url" 2>/dev/null)
        if [[ -n $existing ]] && [[ "$(_gclone_identity "$existing")" == "$(_gclone_identity "$url")" ]]; then
          same=1
          break
        fi
      done
      if [[ -n $same ]]; then
        gum log --level info -- "Already cloned:" path "${target/#$HOME/~}"

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
            gum confirm -- "cd into ${worktrees[1]/#$HOME/~}?" && cd "$worktrees[1]"
          elif (( ${#worktrees} > 1 )); then
            local chosen
            chosen=$(printf '%s\n' "${worktrees[@]/#$HOME/~}" | gum choose --header "cd into which worktree?")
            [[ -n $chosen ]] && cd "${chosen/#\~/$HOME}"
          else
            gum confirm -- "cd into ${target/#$HOME/~}?" && cd "$target"
          fi
          return 0
        fi

        if gum confirm -- "cd into ${target/#$HOME/~}?"; then
          cd "$target"
        fi
        return 0
      fi
      gum log --level error -- "Another repo is already there:" path "${target/#$HOME/~}" origin "${existing:-none}"
      return 1
    fi
    if [[ -n $(print -rl -- "$target"/*(DN[1])) ]]; then
      gum log --level error -- "Folder exists and isn't a git repo:" path "${target/#$HOME/~}"
      return 1
    fi
  fi

  local -a cmd=(git clone)
  if [[ -z $bare && -z $mirror ]]; then
    gum confirm -- "Clone $owner/$repo as a bare repo + worktree?" && bare=1 cmd+=(--bare)
  fi
  cmd+=("$@")
  (( ${#positional} > 1 )) || cmd+=("$target")

  # The first folder this clone creates, so a failed clone can remove what it
  # made (only while empty: other repos may have landed there meanwhile).
  local created=$target
  while [[ ! -e ${created:h} ]]; do created=${created:h}; done
  [[ -e $created ]] && created=
  mkdir -p "${target:h}" || return 1

  local kind=
  [[ -n $bare ]] && kind=" (bare)"
  [[ -n $mirror ]] && kind=" (mirror)"

  # The spinner hides the terminal, so git and ssh must not stop to ask for a
  # password or an unknown host key: they fail instead, and --show-error
  # prints git's own message.
  if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes" \
    gum spin --show-error --title "Cloning $owner/$repo$kind…" -- "${cmd[@]}"; then
    gum log --level error -- "git clone failed:" url "$url"
    _gclone_cleanup "$target" "$created"
    return 1
  fi

  if [[ -n $mirror || -z $bare ]]; then
    cd "$target"
    gum log --level info -- "Cloned${kind}:" path "${target/#$HOME/~}"
    return 0
  fi

  # The remote is origin unless --origin or clone.defaultRemoteName named it
  # otherwise; a fresh clone has only that one.
  local -a remotes=(${(f)"$(git -C "$target" remote)"})
  local remote=$remotes[1]
  local default_branch
  default_branch=$(git -C "$target" symbolic-ref --quiet --short HEAD)
  if [[ -z $default_branch ]]; then
    # --revision detaches HEAD and clones no branch: nothing to add a
    # worktree for, or to fetch.
    gum log --level warn -- "No branch to add a worktree for, HEAD is detached:" path "${target/#$HOME/~}"
    cd "$target"
    return 0
  fi

  # `git clone --bare` mirrors refs/heads/* from the remote into the bare
  # repo's own refs/heads/* once, but -- unlike a plain clone -- leaves
  # remote.<name>.fetch unset, so a later `git fetch` has no refspec and
  # silently fetches nothing. A single-branch clone gets what a plain one
  # would: that branch only.
  if [[ -n $single ]]; then
    git -C "$target" config "remote.$remote.fetch" "+refs/heads/${default_branch}:refs/remotes/$remote/$default_branch"
  else
    git -C "$target" config "remote.$remote.fetch" "+refs/heads/*:refs/remotes/$remote/*"
  fi
  git -C "$target" fetch --prune "$remote" >/dev/null 2>&1

  local worktree=$target/all_worktrees/$default_branch
  if ! git -C "$target" worktree add "$worktree" "$default_branch" >/dev/null 2>&1; then
    gum log --level error -- "Couldn't add the initial worktree:" branch "$default_branch"
    cd "$target"
    return 0
  fi
  # Not set by `worktree add` on its own: the branch exists locally from
  # the bare clone itself, not from a fetch that would have wired tracking up.
  git -C "$worktree" branch --quiet --set-upstream-to="$remote/$default_branch" "$default_branch" >/dev/null 2>&1

  cd "$worktree"
  gum log --level info -- "Cloned bare:" path "${target/#$HOME/~}" worktree "${worktree/#$HOME/~}"
  return 0
}
