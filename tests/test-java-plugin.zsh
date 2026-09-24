#!/usr/bin/env zsh
# Tests private_dot_config/zsh/plugins/java/java.plugin.zsh in isolation: each
# case sources it in a fresh `zsh -c` subshell with $HOME (and PATH, to
# control whether `java` and `mise` are "installed") pointed at a throwaway
# fixture, so it never touches your real mise installs or cache. Run:
# tests/test-java-plugin.zsh
#
# Zsh-specific ($+commands[...], ${(q)...}, ${var:h}), so this must run
# under zsh, not bash.

SCRIPT_DIR="${0:A:h}/.."
SCRIPT="$SCRIPT_DIR/private_dot_config/zsh/plugins/java/java.plugin.zsh"
WORK="$(mktemp -d)"

cleanup() { rm -rf "$WORK" }
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }

# A fake `java` (so $+commands[java] is true) and a fake `mise` whose
# `which catalina.sh` answers $FAKE_CATALINA_SH — set but empty means "mise
# knows no catalina.sh" — and counts its own invocations in $HOME/call-count,
# so tests can tell whether the cache was regenerated or reused. PATH="/bin"
# (no java) is used directly where a test needs java "not installed".
mkdir -p "$WORK/fakebin"
cat > "$WORK/fakebin/java" <<'EOF'
#!/bin/sh
echo fake-java
EOF
cat > "$WORK/fakebin/mise" <<'EOF'
#!/bin/sh
n=$(cat "$HOME/call-count" 2>/dev/null || echo 0)
echo $((n + 1)) > "$HOME/call-count"
[ "$1 $2" = "which catalina.sh" ] || exit 1
answer=${FAKE_CATALINA_SH-/fake/tomcat-9/bin/catalina.sh}
[ -n "$answer" ] || exit 1
echo "$answer"
EOF
chmod +x "$WORK/fakebin/java" "$WORK/fakebin/mise"
FAKE_PATH="$WORK/fakebin:/usr/bin:/bin"

# Runs the plugin in a fresh subshell with $1 as $HOME and $2 as PATH, then
# echoes "$JAVA_HOME|$CATALINA_HOME". JAVA_HOME comes in as $3 (what mise
# would have exported); CATALINA_HOME starts empty.
run_with_home() {
  local fixture_home="$1" fixture_path="$2" java_home="${3-}"
  HOME="$fixture_home" PATH="$fixture_path" SCRIPT="$SCRIPT" JAVA_HOME="$java_home" \
    CATALINA_HOME="" XDG_CACHE_HOME="" XDG_DATA_HOME="" MISE_DATA_DIR="" zsh -c '
    source "$SCRIPT"
    print -r -- "$JAVA_HOME|$CATALINA_HOME"
  '
}

# A fixture where mise has tomcat installed.
with_tomcat() {
  mkdir -p "$1/.local/share/mise/installs/tomcat"
}

### java not installed ###
echo "java not on PATH"

fixture="$WORK/no-java"
with_tomcat "$fixture"
result=$(run_with_home "$fixture" "/bin")
eq "$result" "|" "does nothing at all (no JAVA_HOME, no CATALINA_HOME)"
[[ ! -e "$fixture/.cache" ]] && ok "creates no cache directory" || bad "creates no cache directory"

### JAVA_HOME is mise's business ###
echo "JAVA_HOME"

fixture="$WORK/java-home"
mkdir -p "$fixture"
result=$(run_with_home "$fixture" "$FAKE_PATH" "/from/mise/java-21")
eq "${result%%|*}" "/from/mise/java-21" "leaves the JAVA_HOME mise exported alone"
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result%%|*}" "" "never sets JAVA_HOME itself"

### no tomcat installed ###
echo "no tomcat installed"

fixture="$WORK/no-tomcat"
mkdir -p "$fixture"
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "" "leaves CATALINA_HOME unset"
[[ ! -e "$fixture/call-count" ]] && ok "does not ask mise" || bad "does not ask mise"
[[ ! -e "$fixture/.cache/zsh/init/catalina.zsh" ]] && ok "creates no cache file" || bad "creates no cache file"

### first run: no cache yet, gets created ###
echo "first run creates the cache"

fixture="$WORK/first-run"
with_tomcat "$fixture"
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "/fake/tomcat-9" "sets CATALINA_HOME to the directory above catalina.sh's bin/"
eq "$(cat "$fixture/call-count")" "1" "asks mise exactly once"
[[ -s "$fixture/.cache/zsh/init/catalina.zsh" ]] && ok "leaves a non-empty cache file behind" \
  || bad "leaves a non-empty cache file behind"

### second run: fresh cache is reused, not regenerated ###
echo "fresh cache is reused"

fixture="$WORK/fresh-cache"
with_tomcat "$fixture"
run_with_home "$fixture" "$FAKE_PATH" >/dev/null # first run: creates the cache
result=$(run_with_home "$fixture" "$FAKE_PATH") # second run: should reuse it
eq "${result#*|}" "/fake/tomcat-9" "still sets CATALINA_HOME correctly"
eq "$(cat "$fixture/call-count")" "1" "does not ask mise again"

### stale cache (installs dir newer than the cache) is regenerated ###
echo "stale cache is regenerated"

fixture="$WORK/stale-cache"
with_tomcat "$fixture"
run_with_home "$fixture" "$FAKE_PATH" >/dev/null # first run: creates the cache
touch -t 203001010000 "$fixture/.local/share/mise/installs/tomcat" # simulate a newer install
result=$(FAKE_CATALINA_SH=/fake/tomcat-10/bin/catalina.sh run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "/fake/tomcat-10" "picks up the regenerated value"
eq "$(cat "$fixture/call-count")" "2" "asks mise again"

### empty (zero-byte) cache file is treated as missing ###
echo "empty cache file is regenerated"

fixture="$WORK/empty-cache"
with_tomcat "$fixture"
mkdir -p "$fixture/.cache/zsh/init"
: > "$fixture/.cache/zsh/init/catalina.zsh" # zero-byte, as if a write got cut short
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "/fake/tomcat-9" "regenerates rather than trusting an empty cache"
eq "$(cat "$fixture/call-count")" "1" "asks mise to regenerate it"

### mise knows no catalina.sh ###
echo "mise has no catalina.sh"

fixture="$WORK/no-catalina"
with_tomcat "$fixture"
result=$(FAKE_CATALINA_SH= run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "" "leaves CATALINA_HOME unset"
[[ ! -s "$fixture/.cache/zsh/init/catalina.zsh" ]] && ok "caches no empty answer" \
  || bad "caches no empty answer"

### CATALINA_HOME with a space round-trips through the cache ###
echo "path with a space"

fixture="$WORK/space-path"
with_tomcat "$fixture"
result=$(FAKE_CATALINA_SH="/fake/tomcat home/bin/catalina.sh" run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "/fake/tomcat home" "quotes and unquotes the path correctly through the cache file"

### XDG_CACHE_HOME is respected ###
echo "XDG_CACHE_HOME"

fixture="$WORK/xdg-cache"
with_tomcat "$fixture"
HOME="$fixture" PATH="$FAKE_PATH" SCRIPT="$SCRIPT" XDG_CACHE_HOME="$fixture/xdg-cache" \
  XDG_DATA_HOME="" MISE_DATA_DIR="" JAVA_HOME="" CATALINA_HOME="" zsh -c 'source "$SCRIPT"' >/dev/null
[[ -s "$fixture/xdg-cache/zsh/init/catalina.zsh" ]] && ok "writes the cache under \$XDG_CACHE_HOME" \
  || bad "writes the cache under \$XDG_CACHE_HOME"
[[ ! -e "$fixture/.cache" ]] && ok "does not also write it under \$HOME/.cache" \
  || bad "does not also write it under \$HOME/.cache"

### MISE_DATA_DIR is respected ###
echo "MISE_DATA_DIR"

fixture="$WORK/mise-data-dir"
mkdir -p "$fixture/custom-mise/installs/tomcat"
result=$(HOME="$fixture" PATH="$FAKE_PATH" SCRIPT="$SCRIPT" MISE_DATA_DIR="$fixture/custom-mise" \
  XDG_CACHE_HOME="" XDG_DATA_HOME="" JAVA_HOME="" CATALINA_HOME="" zsh -c '
  source "$SCRIPT"; print -r -- "$CATALINA_HOME"')
eq "$result" "/fake/tomcat-9" "finds mise's tomcat installs under \$MISE_DATA_DIR"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
