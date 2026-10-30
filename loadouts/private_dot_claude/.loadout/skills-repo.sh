#!/bin/sh
# Keeps ~/Repos/gh/josemiguelo/skills cloned (bare + worktree) and symlinks
# each skill it contains into ~/.claude/skills/<name> -- individually, not
# as one directory-level symlink over ~/.claude/skills itself: tools like
# `workmux setup --skills` write their own regenerable skills directly into
# ~/.claude/skills, and a blanket symlink would redirect that regenerable
# content into this tracked repo.
#
# The repo is public: it's fetched over https, so a fresh machine clones it
# before GitHub knows its ssh key, and pushed over ssh (remote.origin.pushurl).
# An existing checkout gets both urls set too.
#
# Modes: `check` / `install` (default).
set -eu

REPO_URL="https://github.com/josemiguelo/skills.git"
PUSH_URL="git@github.com:josemiguelo/skills.git"
REPO="$HOME/Repos/gh/josemiguelo/skills"
SKILLS_DIR="$HOME/.claude/skills"

remotes_ok() {
  [ "$(git -C "$REPO" config --get remote.origin.url)" = "$REPO_URL" ] &&
    [ "$(git -C "$REPO" config --get remote.origin.pushurl)" = "$PUSH_URL" ]
}

set_remotes() {
  git -C "$REPO" config remote.origin.url "$REPO_URL"
  git -C "$REPO" config remote.origin.pushurl "$PUSH_URL"
}

# clone_repo: bare clone + initial worktree, matching gclone --bare's own
# logic (repos.plugin.zsh) for the interactive path. `git clone --bare`
# leaves remote.origin.fetch unconfigured, unlike a plain clone -- without
# setting it explicitly, a later `git fetch` would silently fetch nothing.
clone_repo() {
  git clone --quiet --bare -- "$REPO_URL" "$REPO"
  set_remotes
  git -C "$REPO" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git -C "$REPO" fetch --quiet --prune origin || true

  default_branch=$(git -C "$REPO" symbolic-ref --quiet --short HEAD)
  if [ -z "$default_branch" ]; then
    echo "skills-repo: couldn't determine the default branch" >&2
    return 1
  fi

  worktree="$REPO/all_worktrees/$default_branch"
  git -C "$REPO" worktree add --quiet "$worktree" "$default_branch"
  git -C "$worktree" branch --quiet --set-upstream-to="origin/$default_branch" "$default_branch" || true
}

# The default branch's worktree specifically -- not just whichever one
# `git worktree list` happens to print first. A feature worktree can
# exist alongside it (in-progress work, not yet merged back), and
# symlinks must always converge on the default branch's content, never on
# whatever feature worktree happens to exist at the time.
worktree_path() {
  default_branch=$(git -C "$REPO" symbolic-ref --quiet --short HEAD)
  [ -n "$default_branch" ] || return 0
  git -C "$REPO" worktree list --porcelain 2>/dev/null |
    awk -v want="refs/heads/$default_branch" '/^worktree /{p=$2} $0 == "branch " want {print p; exit}'
}

# Every top-level skill directory the worktree currently has.
skill_names() {
  wt=$(worktree_path)
  [ -n "$wt" ] && [ -d "$wt" ] || return 0
  find "$wt" -mindepth 1 -maxdepth 1 -type d ! -name '.git' -exec basename {} \;
}

# Links in SKILLS_DIR into the worktree whose skill is gone from it (removed
# or renamed in the repo), one per line. Only links into this repo's
# worktree: Omarchy's links and the folders other tools write are never ours.
stale_links() {
  wt=$1
  for link in "$SKILLS_DIR"/*; do
    [ -L "$link" ] || continue
    case "$(readlink "$link")" in
    "$wt"/*) [ -e "$link" ] || printf '%s\n' "$link" ;;
    esac
  done
}

check_all() {
  [ -d "$REPO" ] || return 1
  remotes_ok || return 1
  wt=$(worktree_path)
  [ -n "$wt" ] || return 1

  [ -z "$(stale_links "$wt")" ] || return 1
  names=$(skill_names)
  [ -z "$names" ] && return 0
  while IFS= read -r name; do
    link="$SKILLS_DIR/$name"
    [ -L "$link" ] || return 1
    [ "$(readlink "$link")" = "$wt/$name" ] || return 1
  done <<EOF
$names
EOF
}

install_all() {
  if [ ! -d "$REPO" ]; then
    echo "skills-repo: cloning $REPO_URL"
    clone_repo
  elif ! remotes_ok; then
    set_remotes
    echo "skills-repo: origin fetches over https, pushes over ssh"
  fi

  wt=$(worktree_path)
  if [ -z "$wt" ]; then
    echo "skills-repo: $REPO has no worktree -- clone it manually first" >&2
    return 1
  fi

  mkdir -p "$SKILLS_DIR"
  stale_links "$wt" | while IFS= read -r link; do
    rm "$link"
    echo "skills-repo: unlinked ${link##*/} (gone from the repo)"
  done
  names=$(skill_names)
  [ -z "$names" ] && return 0
  while IFS= read -r name; do
    link="$SKILLS_DIR/$name"
    target="$wt/$name"
    if [ -L "$link" ]; then
      [ "$(readlink "$link")" = "$target" ] || { rm "$link"; ln -s "$target" "$link"; echo "skills-repo: relinked $name"; }
    elif [ -e "$link" ]; then
      echo "skills-repo: $link exists and isn't a symlink; leaving it" >&2
    else
      ln -s "$target" "$link"
      echo "skills-repo: linked $name"
    fi
  done <<EOF
$names
EOF
}

case "${1:-install}" in
check) check_all ;;
install) install_all ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
