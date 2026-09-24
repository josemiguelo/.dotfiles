#!/usr/bin/env zsh
# Tests private_dot_config/zsh/plugins/java/java.plugin.zsh in isolation: each
# case sources it in a fresh `zsh -c` subshell with $HOME (and PATH, to
# control whether `java` is "installed") pointed at a throwaway fixture, so
# it never touches your real asdf installs or cache. Run:
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

# A fake `java` on PATH, so $+commands[java] is true. PATH="/bin" (no java)
# is used directly where a test needs java "not installed".
mkdir -p "$WORK/fakebin"
cat > "$WORK/fakebin/java" <<'EOF'
#!/bin/sh
echo fake-java
EOF
chmod +x "$WORK/fakebin/java"
FAKE_PATH="$WORK/fakebin:/usr/bin:/bin"

# Runs the plugin in a fresh subshell with $1 as $HOME and $2 as PATH, then
# echoes "$JAVA_HOME|$CATALINA_HOME". Starts from a clean slate since the
# plugin only conditionally sets these, never resets them.
run_with_home() {
  local fixture_home="$1" fixture_path="$2"
  HOME="$fixture_home" PATH="$fixture_path" SCRIPT="$SCRIPT" \
    JAVA_HOME="" CATALINA_HOME="" XDG_CACHE_HOME="" zsh -c '
    source "$SCRIPT"
    print -r -- "$JAVA_HOME|$CATALINA_HOME"
  '
}

### java not installed ###
echo "java not on PATH"

fixture="$WORK/no-java"
mkdir -p "$fixture"
result=$(run_with_home "$fixture" "/bin")
eq "$result" "|" "does nothing at all (no JAVA_HOME, no CATALINA_HOME)"
[[ ! -e "$fixture/.cache" ]] && ok "creates no cache directory" || bad "creates no cache directory"

### java installed, no set-java-home.zsh ###
echo "no set-java-home.zsh"

fixture="$WORK/no-set-java-home"
mkdir -p "$fixture"
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result%%|*}" "" "leaves JAVA_HOME unset when asdf's java plugin isn't installed"

### java installed, set-java-home.zsh present ###
echo "set-java-home.zsh present"

fixture="$WORK/with-set-java-home"
mkdir -p "$fixture/.asdf/plugins/java"
cat > "$fixture/.asdf/plugins/java/set-java-home.zsh" <<'EOF'
export JAVA_HOME=/fake/java-home
EOF
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result%%|*}" "/fake/java-home" "sources it and picks up JAVA_HOME"

### no set-catalina-home.sh ###
echo "no set-catalina-home.sh"

fixture="$WORK/no-catalina-script"
mkdir -p "$fixture"
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "" "leaves CATALINA_HOME unset"
[[ ! -e "$fixture/.cache/zsh/init/catalina.zsh" ]] && ok "creates no cache file" || bad "creates no cache file"

# Common fixture for the caching tests below: a set-catalina-home.sh stub
# that exports CATALINA_HOME from $FAKE_CATALINA_HOME and counts its own
# invocations in a call-count file, so tests can tell whether the cache was
# actually regenerated or reused.
setup_catalina_fixture() {
  local fixture="$1"
  mkdir -p "$fixture/.asdf/plugins/tomcat" "$fixture/.asdf/installs/tomcat"
  cat > "$fixture/.asdf/plugins/tomcat/set-catalina-home.sh" <<EOF
#!/bin/sh
count_file="$fixture/call-count"
n=\$(cat "\$count_file" 2>/dev/null || echo 0)
echo \$((n + 1)) > "\$count_file"
export CATALINA_HOME="\${FAKE_CATALINA_HOME:-/fake/catalina-home}"
EOF
}

### first run: no cache yet, gets created ###
echo "first run creates the cache"

fixture="$WORK/first-run"
setup_catalina_fixture "$fixture"
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "/fake/catalina-home" "sets CATALINA_HOME from the freshly-generated cache"
eq "$(cat "$fixture/call-count")" "1" "runs set-catalina-home.sh exactly once"
[[ -s "$fixture/.cache/zsh/init/catalina.zsh" ]] && ok "leaves a non-empty cache file behind" \
  || bad "leaves a non-empty cache file behind"

### second run: fresh cache is reused, not regenerated ###
echo "fresh cache is reused"

fixture="$WORK/fresh-cache"
setup_catalina_fixture "$fixture"
run_with_home "$fixture" "$FAKE_PATH" >/dev/null # first run: creates the cache
result=$(run_with_home "$fixture" "$FAKE_PATH") # second run: should reuse it
eq "${result#*|}" "/fake/catalina-home" "still sets CATALINA_HOME correctly"
eq "$(cat "$fixture/call-count")" "1" "does not run set-catalina-home.sh again"

### stale cache (installs dir newer than the cache) is regenerated ###
echo "stale cache is regenerated"

fixture="$WORK/stale-cache"
setup_catalina_fixture "$fixture"
run_with_home "$fixture" "$FAKE_PATH" >/dev/null # first run: creates the cache
touch -t 203001010000 "$fixture/.asdf/installs/tomcat" # simulate a newer install
FAKE_CATALINA_HOME=/fake/updated-catalina-home \
  result=$(FAKE_CATALINA_HOME=/fake/updated-catalina-home run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "/fake/updated-catalina-home" "picks up the regenerated value"
eq "$(cat "$fixture/call-count")" "2" "runs set-catalina-home.sh again"

### empty (zero-byte) cache file is treated as missing ###
echo "empty cache file is regenerated"

fixture="$WORK/empty-cache"
setup_catalina_fixture "$fixture"
mkdir -p "$fixture/.cache/zsh/init"
: > "$fixture/.cache/zsh/init/catalina.zsh" # zero-byte, as if a write got cut short
result=$(run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "/fake/catalina-home" "regenerates rather than trusting an empty cache"
eq "$(cat "$fixture/call-count")" "1" "runs set-catalina-home.sh to regenerate it"

### CATALINA_HOME with a space round-trips through the cache ###
echo "path with a space"

fixture="$WORK/space-path"
setup_catalina_fixture "$fixture"
result=$(FAKE_CATALINA_HOME="/fake/catalina home" run_with_home "$fixture" "$FAKE_PATH")
eq "${result#*|}" "/fake/catalina home" "quotes and unquotes the path correctly through the cache file"

### XDG_CACHE_HOME is respected ###
echo "XDG_CACHE_HOME"

fixture="$WORK/xdg-cache"
setup_catalina_fixture "$fixture"
HOME="$fixture" PATH="$FAKE_PATH" SCRIPT="$SCRIPT" XDG_CACHE_HOME="$fixture/xdg-cache" \
  JAVA_HOME="" CATALINA_HOME="" zsh -c 'source "$SCRIPT"' >/dev/null
[[ -s "$fixture/xdg-cache/zsh/init/catalina.zsh" ]] && ok "writes the cache under \$XDG_CACHE_HOME" \
  || bad "writes the cache under \$XDG_CACHE_HOME"
[[ ! -e "$fixture/.cache" ]] && ok "does not also write it under \$HOME/.cache" \
  || bad "does not also write it under \$HOME/.cache"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
