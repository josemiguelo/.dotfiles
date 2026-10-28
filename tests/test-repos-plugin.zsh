#!/usr/bin/env zsh
# Tests loadouts/private_dot_config/zsh/plugins/repos/repos.plugin.zsh (gclone) in
# isolation: $HOME is a fixture inside a fresh mktemp directory (so ~/Repos is
# too), and git's url.<base>.insteadOf (in a throwaway global config) redirects
# the GitHub URLs to local repos, so clones are real but never touch the
# network. gum is the real binary except `confirm`, which needs a terminal: a
# stand-in answers it from $GCLONE_TEST_CONFIRM (yes/no).
#
# Safety: the script refuses to run unless its work directory is a fresh
# directory under the system temp dir, and every removal goes through
# fixture_rm, which refuses anything outside that directory. It never deletes
# a path built only from $HOME. Run: tests/test-repos-plugin.zsh

SCRIPT_DIR="${0:A:h}/.."
PLUGIN="$SCRIPT_DIR/loadouts/private_dot_config/zsh/plugins/repos/repos.plugin.zsh"
REAL_HOME=$HOME

WORK="$(mktemp -d)" || exit 1
WORK=${WORK:A}
if [[ -z $WORK || $WORK != ${TMPDIR:-/tmp}/* || ! -d $WORK ]]; then
  print -u2 "refusing to run: work dir [$WORK] isn't a fresh temp directory"
  exit 1
fi

# Remove a path, only if it's inside $WORK.
fixture_rm() {
  local target=${1:A}
  if [[ -z $target || $target != $WORK/* ]]; then
    print -u2 "refusing to remove [$1]: outside the test directory $WORK"
    exit 1
  fi
  rm -rf -- "$target"
}

cleanup() {
  [[ -n $WORK && $WORK == ${TMPDIR:-/tmp}/* ]] && rm -rf -- "$WORK"
}
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }

source "$PLUGIN"

echo "URL parsing"
parse() { local -a reply; _gclone_parse "$1" && print -r -- "$reply[2]/$reply[3]/$reply[4]" || print -r -- REJECTED }
eq "$(parse git@github.com:ai-hero-dev/ai-coding-crash-course.git)" gh/ai-hero-dev/ai-coding-crash-course "ssh scp-style, .git dropped"
eq "$(parse https://github.com/ai-hero-dev/ai-coding-crash-course)" gh/ai-hero-dev/ai-coding-crash-course "https"
eq "$(parse ssh://git@github.com:22/owner/repo.git)" gh/owner/repo "ssh:// with a port"
eq "$(parse https://github.com/owner/repo/tree/main/src)" gh/owner/repo "browser URL keeps owner/repo"
eq "$(parse https://github.com/owner/repo/)" gh/owner/repo "trailing slash"
eq "$(parse 'https://github.com/o/r?tab=readme')" gh/o/r "query string"
eq "$(parse https://WWW.GitHub.com/Owner/Repo.git)" gh/Owner/Repo "www. and host case; repo case kept"
eq "$(parse https://gitlab.com/group/sub/repo.git)" gl/sub/repo "GitLab subgroup keeps only sub/repo"
eq "$(parse https://gitlab.com/group/sub/repo/-/blob/main/README.md)" gl/sub/repo "GitLab page URL"
eq "$(parse https://bitbucket.org/team/repo/src/main/)" bb/team/repo "Bitbucket"
eq "$(parse https://codeberg.org/u/r.git)" cb/u/r "Codeberg"
eq "$(parse https://git.sr.ht/~user/tool)" srht/user/tool "sr.ht, ~ dropped"
eq "$(parse https://git.example.com/team/tool.git)" git.example.com/team/tool "unknown host keeps its name"
eq "$(parse https://github.com/onlyowner)" REJECTED "owner without repo rejected"
eq "$(parse notaurl)" REJECTED "not a URL rejected"
eq "$(parse https://github.com/../x)" REJECTED "dot segments rejected"

echo "reading git clone's arguments"
args() {
  local -a positional; local bare mirror single help
  _gclone_args "$@" || return
  print -r -- "${(j:|:)positional} bare=$bare mirror=$mirror single=$single help=$help"
}
eq "$(args --bare u)" "u bare=1 mirror= single= help=" "--bare before the URL"
eq "$(args u --bare)" "u bare=1 mirror= single= help=" "--bare after the URL"
eq "$(args --bare --no-bare u)" "u bare= mirror= single= help=" "the last of --bare/--no-bare wins"
eq "$(args -b main u)" "u bare= mirror= single= help=" "-b takes the next argument"
eq "$(args --branch main u d)" "u|d bare= mirror= single= help=" "--branch takes the next argument; then URL and folder"
eq "$(args --branch=main u)" "u bare= mirror= single= help=" "--branch=value"
eq "$(args -qb main u)" "u bare= mirror= single= help=" "a short bundle ending in -b takes the next argument"
eq "$(args -bmain u)" "u bare= mirror= single= help=" "-bvalue"
eq "$(args -c core.x=y -o up u)" "u bare= mirror= single= help=" "-c and -o take the next argument"
eq "$(args --depth 1 u)" "u bare= mirror= single=1 help=" "--depth implies --single-branch"
eq "$(args --depth 1 --no-single-branch u)" "u bare= mirror= single= help=" "--no-single-branch overrides that"
eq "$(args --single-branch u)" "u bare= mirror= single=1 help=" "--single-branch"
eq "$(args --mirror u)" "u bare= mirror=1 single= help=" "--mirror"
eq "$(args -- --bare d)" "--bare|d bare= mirror= single= help=" "after --, everything is positional"
eq "$(args u -h)" "u bare= mirror= single= help=1" "-h anywhere"

eq "$(args --dep 1 u)" "u bare= mirror= single=1 help=" "shortened --dep is --depth, with its value"
eq "$(args --ba u)" "u bare=1 mirror= single= help=" "shortened --ba is --bare"
eq "$(args --no-sing --dep 1 u)" "u bare= mirror= single= help=" "shortened --no-sing is --no-single-branch"
eq "$(args --naked u)" "u bare=1 mirror= single= help=" "--naked, git's hidden alias of --bare"
eq "$(args --rec u)" "u bare= mirror= single= help=" "--rec matches an option and its alias: not ambiguous"
args --ref x u >/dev/null 2>&1
eq "$?" 1 "an ambiguous option fails, as in git"
args --zzz u >/dev/null 2>&1
eq "$?" 1 "an unknown option fails, as in git"
[[ "$(args --ref x u 2>&1)" == *'could be'*'--ref-format'* ]] && ok "the error names the candidates" || bad "ambiguity error: $(args --ref x u 2>&1)"

# Short options taking a value aren't in git's completion list, so they're
# kept by hand: they must still match git clone -h. The aliases must still be
# options git knows.
setopt extended_glob
git_short=
for line in ${(f)"$(git clone -h 2>&1)"}; do
  [[ $line == (#b)[[:space:]]##-([[:alnum:]]),[[:space:]]##--(\[no-\]|)[[:alnum:]-]##[[:space:]]##\<* ]] && git_short+=$match[1]
done
eq "${(j::)${(os::)git_short}}" "${(j::)${(os::)_GCLONE_VALUE_SHORT}}" "short options taking a value match git clone -h"
helper=" $(git clone --git-completion-helper-all) "
for a in ${(k)_GCLONE_ALIASES}; do
  [[ $helper == *" $a "* && $helper == *" $_GCLONE_ALIASES[$a] "* ]] && ok "git still knows $a and $_GCLONE_ALIASES[$a]" || bad "git no longer lists $a or $_GCLONE_ALIASES[$a]"
done

# From here on gclone runs for real, so $HOME moves into the fixture first.
export HOME="$WORK/home"
mkdir -p "$HOME"
if [[ $HOME == $REAL_HOME || $HOME != $WORK/* ]]; then
  print -u2 "refusing to run: HOME [$HOME] isn't inside the test directory"
  exit 1
fi
REPOS="$WORK/home/Repos"
TARGET="$REPOS/gh/acme/widget"

# Local repos the GitHub URLs are redirected to.
git init -q "$WORK/widget" && git -C "$WORK/widget" commit -q --allow-empty -m init
export GIT_CONFIG_GLOBAL="$WORK/gitconfig"
git config --global url."$WORK/widget".insteadOf "git@github.com:acme/widget.git"
git config --global --add url."$WORK/widget".insteadOf "https://github.com/acme/widget"
git config --global user.name test
git config --global user.email test@example.com

# gum stand-in: answers `confirm` from $GCLONE_TEST_CONFIRM, the rest is real.
FAKEBIN="$WORK/fakebin"
mkdir -p "$FAKEBIN"
REAL_GUM=${commands[gum]}
print -r -- '#!/bin/sh' > "$FAKEBIN/gum"
print -r -- 'if [ "$1" = confirm ]; then [ "$GCLONE_TEST_CONFIRM" = yes ]; exit; fi' >> "$FAKEBIN/gum"
print -r -- "exec \"$REAL_GUM\" \"\$@\"" >> "$FAKEBIN/gum"
chmod +x "$FAKEBIN/gum"
path=( "$FAKEBIN" $path )
hash -r

echo "cloning"
cd "$WORK"
gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$?" 0 "clone succeeds"
eq "$PWD" "$TARGET" "cds into the new clone"
[[ -d $TARGET/.git ]] && ok "cloned under ~/Repos/gh/acme/widget" || bad "no clone at $TARGET"

echo "existing clone of the same repo"
cd "$WORK"
GCLONE_TEST_CONFIRM=yes gclone https://github.com/acme/widget >/dev/null 2>&1
eq "$?" 0 "same repo by another URL form: ok"
eq "$PWD" "$TARGET" "answering yes cds there"
cd "$WORK"
GCLONE_TEST_CONFIRM=no gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$PWD" "$WORK" "answering no stays put"

echo "folder holds another repo"
git -C "$TARGET" remote set-url origin https://github.com/someone/else.git
cd "$WORK"
gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$?" 1 "a different repo there is an error"
eq "$(git -C "$TARGET" remote get-url origin)" https://github.com/someone/else.git "the other repo is left alone"
fixture_rm "$REPOS"

echo "folder isn't a repo"
mkdir -p "$TARGET" && touch "$TARGET/notes.txt"
gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$?" 1 "a non-empty non-repo folder is an error"
[[ -f $TARGET/notes.txt && ! -d $TARGET/.git ]] && ok "its files are left alone" || bad "folder was touched"
fixture_rm "$REPOS"

echo "bare repo already there"
mkdir -p "${TARGET:h}" && git clone -q --bare git@github.com:acme/widget.git "$TARGET"
cd "$WORK"
GCLONE_TEST_CONFIRM=yes gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$PWD" "$TARGET" "a bare clone of the same repo counts as cloned"
fixture_rm "$REPOS"

echo "failed clone"
cd "$WORK"
gclone git@github.com:acme/missing.git >/dev/null 2>&1
eq "$?" 1 "clone of a missing repo fails"
[[ ! -e $REPOS ]] && ok "leaves no empty folders behind" || bad "left $(find "$REPOS")"
mkdir -p "$REPOS/gh/acme/keep"
gclone git@github.com:acme/missing.git >/dev/null 2>&1
[[ -d $REPOS/gh/acme/keep && ! -e $REPOS/gh/acme/missing ]] && ok "keeps folders it didn't create" || bad "removed or left the wrong folders"
fixture_rm "$REPOS"

echo "--bare, anywhere"
DEFAULT=$(git -C "$WORK/widget" branch --show-current)
cd "$WORK"
GCLONE_TEST_CONFIRM=no gclone --bare git@github.com:acme/widget.git >/dev/null 2>&1
eq "$?" 0 "--bare before the URL clones"
eq "$(git -C "$TARGET" rev-parse --is-bare-repository)" true "bare, without asking"
eq "$PWD" "$TARGET/all_worktrees/$DEFAULT" "cds into the default branch's worktree"
eq "$(git -C "$TARGET" config remote.origin.fetch)" "+refs/heads/*:refs/remotes/origin/*" "fetch refspec set"
eq "$(git -C "$TARGET/all_worktrees/$DEFAULT" rev-parse --abbrev-ref @{u})" "origin/$DEFAULT" "worktree tracks origin"
fixture_rm "$REPOS"

echo "no --bare: asks"
cd "$WORK"
GCLONE_TEST_CONFIRM=yes gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$(git -C "$TARGET" rev-parse --is-bare-repository)" true "answering yes clones bare"
eq "$PWD" "$TARGET/all_worktrees/$DEFAULT" "with the worktree"
fixture_rm "$REPOS"

echo "--origin"
cd "$WORK"
gclone -o upstream --bare git@github.com:acme/widget.git >/dev/null 2>&1
eq "$(git -C "$TARGET" config remote.upstream.fetch)" "+refs/heads/*:refs/remotes/upstream/*" "refspec uses the given remote name"
eq "$(git -C "$TARGET/all_worktrees/$DEFAULT" rev-parse --abbrev-ref @{u})" "upstream/$DEFAULT" "worktree tracks it"
cd "$WORK"
GCLONE_TEST_CONFIRM=yes gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$PWD" "$TARGET/all_worktrees/$DEFAULT" "a clone with another remote name still counts as cloned"
fixture_rm "$REPOS"

echo "--mirror"
cd "$WORK"
GCLONE_TEST_CONFIRM=yes gclone git@github.com:acme/widget.git --mirror >/dev/null 2>&1
eq "$(git -C "$TARGET" config remote.origin.fetch)" "+refs/*:refs/*" "the mirror's own refspec is kept"
[[ ! -e $TARGET/all_worktrees ]] && ok "no worktree" || bad "added a worktree"
eq "$PWD" "$TARGET" "cds into the mirror"
fixture_rm "$REPOS"

echo "an explicit folder"
cd "$WORK"
mkdir -p "$WORK/here"
cd "$WORK/here"
gclone git@github.com:acme/widget.git there >/dev/null 2>&1
eq "$PWD" "$WORK/here/there" "clones into it, relative to where gclone runs"
[[ ! -e $REPOS ]] && ok "nothing under ~/Repos" || bad "cloned under ~/Repos too"
cd "$WORK/here"
gclone --bare git@github.com:acme/widget.git bare >/dev/null 2>&1
eq "$PWD" "$WORK/here/bare/all_worktrees/$DEFAULT" "--bare puts all_worktrees in it"
fixture_rm "$WORK/here"

echo "shortened options reach git as given"
cd "$WORK"
GCLONE_TEST_CONFIRM=no gclone --ba git@github.com:acme/widget.git >/dev/null 2>&1
eq "$PWD" "$TARGET/all_worktrees/$DEFAULT" "--ba clones bare, with the worktree"
fixture_rm "$REPOS"
cd "$WORK"
gclone --zzz git@github.com:acme/widget.git >/dev/null 2>&1
eq "$?" 1 "an unknown option stops before cloning"
[[ ! -e $REPOS ]] && ok "and creates nothing" || bad "created $REPOS"

echo "git clone options pass through"
cd "$WORK"
# A shallow clone needs a file:// URL; a plain path ignores --depth.
git config --global --unset-all url."$WORK/widget".insteadOf
git config --global protocol.file.allow always
git config --global url."file://$WORK/widget".insteadOf "git@github.com:acme/widget.git"
gclone git@github.com:acme/widget.git --depth 1 >/dev/null 2>&1
eq "$(git -C "$TARGET" rev-parse --is-shallow-repository 2>/dev/null)" true "--depth 1 reaches git clone"
fixture_rm "$REPOS"
cd "$WORK"
gclone --depth 1 --bare git@github.com:acme/widget.git >/dev/null 2>&1
eq "$(git -C "$TARGET" config remote.origin.fetch)" "+refs/heads/${DEFAULT}:refs/remotes/origin/$DEFAULT" "a shallow bare clone fetches only its branch"

echo "usage"
gclone >/dev/null 2>&1
eq "$?" 1 "no argument: usage, exit 1"
usage=$(gclone 2>&1)
[[ $usage == *'gclone [git clone options] <url>'* && $usage == *'--bare'* && $usage != *'Usage: gum'* ]] \
  && ok "prints gclone's own usage, not gum's" || bad "usage is gum's help or missing"
gclone --help >/dev/null 2>&1
eq "$?" 0 "--help: exit 0"
gclone notaurl >/dev/null 2>&1
eq "$?" 1 "not a URL: exit 1"
out=$(gclone --bare 2>&1)
eq "$?" 1 "--bare and no URL: exit 1"
[[ $out == *'Not a repository URL'* && $out != *'Usage: gum'* ]] \
  && ok "the error is gclone's, not gum's help" || bad "error output: $out"

echo
echo "$pass passed, $fail failed"
(( fail == 0 ))
