#!/usr/bin/env zsh
# Tests private_dot_config/zsh/plugins/android/android.plugin.zsh in
# isolation: each case sources it in a fresh `zsh -c` subshell with $HOME
# pointed at a throwaway fixture directory, so it never touches your real
# Android SDK install or PATH. Run: tests/test-android-plugin.zsh
#
# Zsh-specific ((N), (/Nn) glob qualifiers), so this must run under zsh, not
# bash — it can't even be parsed by bash.

SCRIPT_DIR="${0:A:h}/.."
SCRIPT="$SCRIPT_DIR/private_dot_config/zsh/plugins/android/android.plugin.zsh"
WORK="$(mktemp -d)"

cleanup() { rm -rf "$WORK" }
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])" }
not_contains() { [[ "$1" != *"$2"* ]] && ok "$3" || bad "$3 (expected NOT to contain [$2], got [$1])" }

# Runs the plugin in a fresh subshell with $1 as $HOME, then echoes
# "$ANDROID_HOME|$ANDROID_SDK_ROOT|$PATH" so the caller can assert on it. The
# plugin only conditionally overwrites these — it never resets them — so
# start from a clean slate rather than inheriting this machine's real values.
run_with_home() {
  local fixture_home="$1"
  HOME="$fixture_home" SCRIPT="$SCRIPT" PATH="/usr/bin:/bin" \
    ANDROID_HOME="" ANDROID_SDK_ROOT="" zsh -c '
    source "$SCRIPT"
    print -r -- "$ANDROID_HOME|$ANDROID_SDK_ROOT|$PATH"
  '
}

### no SDK directory at all ###
echo "no SDK directory"

fixture="$WORK/none"
mkdir -p "$fixture"
result=$(run_with_home "$fixture")
eq "${result%%|*}" "" "leaves ANDROID_HOME unset"

### capitalized Sdk ###
echo "capitalized Sdk"

fixture="$WORK/cap"
mkdir -p "$fixture/Library/Android/Sdk/platform-tools"
result=$(run_with_home "$fixture")
android_home="${result%%|*}"
eq "$android_home" "$fixture/Library/Android/Sdk" "finds Sdk (capitalized)"
contains "$result" "$android_home/platform-tools" "adds platform-tools to PATH"

### lowercase sdk ###
echo "lowercase sdk"

fixture="$WORK/lower"
mkdir -p "$fixture/Library/Android/sdk/platform-tools"
result=$(run_with_home "$fixture")
eq "${result%%|*}" "$fixture/Library/Android/sdk" "finds sdk (lowercase), tolerating the case difference"

### both Sdk and sdk exist ###
echo "both Sdk and sdk exist"

fixture="$WORK/both"
mkdir -p "$fixture/Library/Android/Sdk" "$fixture/Library/Android/sdk"
result=$(run_with_home "$fixture")
eq "${result%%|*}" "$fixture/Library/Android/Sdk" "picks Sdk over sdk (glob order, not a documented guarantee — pinned here so a future zsh/glob change is visible)"

### ANDROID_SDK_ROOT mirrors ANDROID_HOME ###
echo "ANDROID_SDK_ROOT"

fixture="$WORK/mirror"
mkdir -p "$fixture/Library/Android/Sdk"
result=$(run_with_home "$fixture")
parts=("${(@s:|:)result}")
eq "${parts[2]}" "${parts[1]}" "ANDROID_SDK_ROOT is set to the same path as ANDROID_HOME"

### build-tools: highest version wins, including natural (not lexicographic) sort ###
echo "build-tools version picking"

fixture="$WORK/versions"
mkdir -p "$fixture/Library/Android/Sdk/build-tools/9.0.0"
mkdir -p "$fixture/Library/Android/Sdk/build-tools/28.0.3"
mkdir -p "$fixture/Library/Android/Sdk/build-tools/34.0.0"
result=$(run_with_home "$fixture")
contains "$result" "build-tools/34.0.0" \
  "picks the highest version (34.0.0), not the lexicographically-last one (9.0.0)"
not_contains "$result" "build-tools/9.0.0:" "does not add the lower versions to PATH"

### build-tools directory missing ###
echo "no build-tools directory"

fixture="$WORK/no-buildtools-dir"
mkdir -p "$fixture/Library/Android/Sdk/platform-tools"
result=$(run_with_home "$fixture")
not_contains "$result" "/build-tools/" "does not add a build-tools entry"
contains "$result" "platform-tools" "still adds the rest of the SDK PATH entries"

### build-tools directory present but empty ###
echo "empty build-tools directory"

fixture="$WORK/empty-buildtools-dir"
mkdir -p "$fixture/Library/Android/Sdk/build-tools"
result=$(run_with_home "$fixture")
not_contains "$result" "/build-tools/" "adds no build-tools version when none are installed"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
