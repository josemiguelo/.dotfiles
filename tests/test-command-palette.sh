#!/usr/bin/env bash
# Tests configs/private_dot_local/bin/executable_command-palette end to end: the
# registry is read, the picked command gets the typed text as its arguments, TMUX
# is unset before zsh runs it, and a failure is held on screen. fzf and zsh are
# fakes on a throwaway $HOME's PATH, so no real picker or tmux session opens.
# Run: tests/test-command-palette.sh
set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/private_dot_local/bin/executable_command-palette"
BREW_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/private_dot_local/lib/brew-prefix.sh"

fix=$(mktemp -d)
trap 'rm -rf "$fix"' EXIT
mkdir -p "$fix/.local/bin" "$fix/.local/lib" "$fix/.config/fzf" "$fix/.config/command-palette"
cp "$BREW_LIB" "$fix/.local/lib/brew-prefix.sh"
echo '# theme stub' >"$fix/.config/fzf/theme.sh"

# The registry the cases use (the real one is a template, rendered per machine).
REGISTRY="$fix/registry"
printf '# comment\n\nstart-dotfiles-change\tnew try folder\n' >"$REGISTRY"

# Fake fzf: records what it was given, then prints the first line matching
# $FAKE_PICK (the first line when unset), or fails when FAKE_CANCEL is set.
cat >"$fix/.local/bin/fzf" <<'EOF'
#!/usr/bin/env bash
cat >"$FZF_INPUT"
[[ -z "${FAKE_CANCEL:-}" ]] || exit 130
grep -m1 -F -- "${FAKE_PICK:-}" "$FZF_INPUT"
EOF

# Fake gum: logs its command line to $GUM_LOG and exits with $FAKE_GUM_STATUS
# (0 for Yes, 1 for No, 130 for Ctrl-C).
cat >"$fix/.local/bin/gum" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$GUM_LOG"
exit "${FAKE_GUM_STATUS:-0}"
EOF

# Fake zsh: the argument prompt (a `vared` call) logs its command line to
# $ZSH_PROMPT_LOG, reads the typed line from stdin, and writes it to the file
# the palette passed last, as the real prompt does. Any other call logs whether
# TMUX is set and the command line it got, then exits with $FAKE_ZSH_STATUS.
cat >"$fix/.local/bin/zsh" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *'vared -p'* ]]; then
  printf '%s\n' "$*" >>"$ZSH_PROMPT_LOG"
  IFS= read -r line
  printf '%s\n' "$line" >"${@: -1}"
  exit 0
fi
printf '%s\n' "$PATH" >"$ZSH_PATH_LOG"
printf '%s|%s\n' "${TMUX:-unset}" "$*" >>"$ZSH_LOG"
exit "${FAKE_ZSH_STATUS:-0}"
EOF
chmod +x "$fix/.local/bin/fzf" "$fix/.local/bin/zsh" "$fix/.local/bin/gum"

# Runs the palette with the given stdin; sets out (stdout+stderr) and status.
run_palette() {
  : >"$fix/zsh.log"
  : >"$fix/prompt.log"
  : >"$fix/gum.log"
  out=$(env -i HOME="$fix" PATH="/usr/bin:/bin" XDG_CONFIG_HOME="$fix/.config" \
    COMMAND_PALETTE_COMMANDS="${REGISTRY_FILE:-$REGISTRY}" \
    FZF_INPUT="$fix/fzf.in" ZSH_LOG="$fix/zsh.log" ZSH_PROMPT_LOG="$fix/prompt.log" ZSH_PATH_LOG="$fix/path.log" \
    GUM_LOG="$fix/gum.log" TMUX=/fake/tmux,1,0 \
    "$@" bash "$SCRIPT" 2>&1)
  status=$?
}

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }

echo "command-palette"

# Typed text becomes the command's arguments, and TMUX is unset for the run.
run_palette FAKE_PICK=start-dotfiles-change < <(printf 'hello world\n')
eq "$(cat "$fix/zsh.log")" "unset|-ic start-dotfiles-change hello world" \
  "picked command runs with the typed text as arguments, TMUX unset"
eq "$status" "0" "successful command: palette exits 0"

# The command's PATH has what a login shell would add on macOS (/usr/local/bin,
# where docker is linked), though the palette starts from launchd's bare PATH.
if [[ -x /usr/libexec/path_helper ]]; then
  run_palette FAKE_PICK=start-dotfiles-change < <(printf 'x\n')
  case ":$(cat "$fix/path.log"):" in
  *:/usr/local/bin:*) ok "PATH includes path_helper's entries (/usr/local/bin)" ;;
  *) bad "PATH includes path_helper's entries (got [$(cat "$fix/path.log")])" ;;
  esac
fi

# The argument prompt is zsh's vared (its line editor and key bindings), with
# the picked name as its prompt.
case "$(cat "$fix/prompt.log")" in
*'vared -p "$1 " args'*' _ start-dotfiles-change '*) ok "arguments are edited by zsh's vared, prompting with the name" ;;
*) bad "arguments are edited by zsh's vared (got [$(cat "$fix/prompt.log")])" ;;
esac

# The picker is fed the registry without comments or blank lines.
run_palette FAKE_PICK=start-dotfiles-change < <(printf '\n')
eq "$(cut -f2 "$fix/fzf.in")" "start-dotfiles-change" \
  "picker lists the registry's commands only"

# The picker shows a table: names padded to the longest so the descriptions
# start in the same column, each column in its own color.
printf 'short\tdoes a thing\nmuch-longer-name\tother thing\tnvim -c Foo\n' >"$fix/table"
REGISTRY_FILE="$fix/table" run_palette FAKE_PICK=short < <(printf '\n')
plain=$(cut -f1 "$fix/fzf.in" | sed $'s/\033\\[[0-9;]*m//g')
eq "$(printf '%s\n' "$plain" | awk '{ print index($0, "does") ? index($0, "does") : index($0, "other") }' | sort -u | wc -l | tr -d ' ')" "1" \
  "descriptions start in the same column"
case "$(head -1 "$fix/fzf.in")" in
*$'\033[1;34m'short*$'\033[32m'does*) ok "name and description are in different colors" ;;
*) bad "name and description are in different colors (got [$(head -1 "$fix/fzf.in")])" ;;
esac
# What the picker returns says what was picked: the name, and the command line
# of a line that has one.
REGISTRY_FILE="$fix/table" run_palette FAKE_PICK=much-longer < <(printf 'x\n')
eq "$(cat "$fix/zsh.log")" "unset|-ic nvim -c Foo x" "a picked table row runs its command line"
REGISTRY_FILE="$fix/table" run_palette FAKE_PICK=short < <(printf 'x\n')
eq "$(cat "$fix/zsh.log")" "unset|-ic short x" "a picked table row without a command line runs its name"

# With no arguments typed, the command runs with none.
run_palette FAKE_PICK=start-dotfiles-change < <(printf '\n')
eq "$(cat "$fix/zsh.log")" "unset|-ic start-dotfiles-change " \
  "empty input runs the command with no arguments"

# After the pick, the question is gum's Yes/No confirm, with its default buttons.
run_palette FAKE_PICK=start-dotfiles-change < <(printf 'x\n')
case "$(cat "$fix/gum.log")" in
'confirm Enter arguments for this command?') ok "arguments question is a plain Yes/No confirm" ;;
*) bad "arguments question is a plain Yes/No confirm (got [$(cat "$fix/gum.log")])" ;;
esac

# No: the command runs with no arguments, and no prompt opens.
run_palette FAKE_PICK=start-dotfiles-change FAKE_GUM_STATUS=1 < <(printf 'ignored\n')
eq "$(cat "$fix/zsh.log")" "unset|-ic start-dotfiles-change " \
  "No: command runs with no arguments"
eq "$(cat "$fix/prompt.log")" "" "No: no argument prompt opens"

# Ctrl-C at the question (gum exits 130): nothing runs, and the palette exits 0.
run_palette FAKE_PICK=start-dotfiles-change FAKE_GUM_STATUS=130 < <(printf 'x\n')
eq "$(cat "$fix/zsh.log")" "" "Ctrl-C at the question: no command runs"
eq "$status" "0" "Ctrl-C at the question: palette exits 0"

# A custom registry: the picked line's name is what runs, not its description.
printf '# comment\n\nalpha\tfirst thing\nbeta\tsecond thing\n' >"$fix/custom"
REGISTRY_FILE="$fix/custom" run_palette FAKE_PICK=beta < <(printf 'x\n')
eq "$(cat "$fix/zsh.log")" "unset|-ic beta x" \
  "the name before the tab runs, not the description"

# A third field is the command line to run; the name is only a label, and the
# picker is told to show just the name and description.
printf 'My Label\tdoes a thing\tnvim -c Foo\n' >"$fix/labelled"
REGISTRY_FILE="$fix/labelled" run_palette FAKE_PICK=Label < <(printf 'x\n')
eq "$(cat "$fix/zsh.log")" "unset|-ic nvim -c Foo x" \
  "a third field runs instead of the name"
case "$(cat "$fix/prompt.log")" in
*' _ My Label '*) ok "the argument prompt still uses the label" ;;
*) bad "the argument prompt still uses the label (got [$(cat "$fix/prompt.log")])" ;;
esac

# Esc in the picker: nothing runs.
run_palette FAKE_CANCEL=1 < <(printf 'x\n')
eq "$(cat "$fix/zsh.log")" "" "cancelled picker: no command runs"
eq "$status" "0" "cancelled picker: palette exits 0"

# A failing command is held on screen until a key is pressed.
run_palette FAKE_PICK=start-dotfiles-change FAKE_ZSH_STATUS=3 < <(printf 'x\n\n')
eq "$status" "3" "failing command: palette exits with its status"
case "$out" in
*"start-dotfiles-change exited 3"*) ok "failing command: its status is shown before the palette closes" ;;
*) bad "failing command: its status is shown (got [$out])" ;;
esac

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
