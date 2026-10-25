#!/bin/sh
# josemiguelo's repos named by the machine (`run(bareRepos, "loadout",
# "loadout.wiki")`), each a bare clone in ~/Repos/gh/josemiguelo/<repo> with
# its default branch checked out in all_worktrees/<branch>, the layout
# `gclone --bare` (repos.plugin.zsh) makes by hand and skills-repo.sh keeps
# for skills. Public repos: fetched over https, so a fresh machine clones them
# before GitHub knows its ssh key, and pushed over ssh. An existing clone only
# gets both urls set; nothing else in it is touched.
# usage: bare-repos.sh [check] <repo>...
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
[ "$#" -gt 0 ] || { echo "usage: $0 [check] <repo>..." >&2; exit 2; }

# `git clone --bare` leaves remote.origin.fetch unset, so a later fetch would
# fetch nothing; it's set here as gclone --bare does.
clone() {
  git clone --quiet --bare -- "$url" "$dir"
  set_remotes
  git -C "$dir" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git -C "$dir" fetch --quiet --prune origin || true
  branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD) ||
    { echo "bare-repos: no default branch in $dir" >&2; return 1; }
  git -C "$dir" worktree add --quiet "$dir/all_worktrees/$branch" "$branch"
  git -C "$dir/all_worktrees/$branch" branch --quiet --set-upstream-to="origin/$branch" "$branch" || true
}

set_remotes() {
  git -C "$dir" config remote.origin.url "$url"
  git -C "$dir" config remote.origin.pushurl "$push"
}

remotes_ok() {
  [ "$(git -C "$dir" config --get remote.origin.url)" = "$url" ] &&
    [ "$(git -C "$dir" config --get remote.origin.pushurl)" = "$push" ]
}

# The default branch's worktree exists.
worktree_ok() {
  branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD) || return 1
  [ -d "$dir/all_worktrees/$branch" ]
}

rc=0
for repo in "$@"; do
  dir="$HOME/Repos/gh/josemiguelo/$repo"
  url="https://github.com/josemiguelo/$repo.git"
  push="git@github.com:josemiguelo/$repo.git"
  if [ "$MODE" = check ]; then
    { [ -d "$dir" ] && remotes_ok && worktree_ok; } || { echo "missing: $repo"; rc=1; }
  elif [ ! -d "$dir" ]; then
    echo "bare-repos: cloning $url"
    mkdir -p "$(dirname "$dir")"
    clone || rc=1
  else
    remotes_ok || { set_remotes; echo "bare-repos: $repo fetches over https, pushes over ssh"; }
    worktree_ok || { echo "bare-repos: $dir has no worktree for its default branch" >&2; rc=1; }
  fi
done
exit "$rc"
