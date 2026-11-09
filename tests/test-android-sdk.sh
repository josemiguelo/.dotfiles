#!/usr/bin/env bash
# Tests loadouts/private_dot_config/.android-sdk/.loadout/ (sdk.ts,
# outdated-sdk.ts, lib/android-sdk.ts): each case runs them in a copy of the
# repo's few files they use (package.json resolves #loadout and #android-sdk),
# with a pins file of its own, so `update` never rewrites the repo's, and
# $HOME pointed at a fixture holding a fake SDK, a fake Android Studio JDK and
# a fake sdkmanager that logs its arguments and "installs" by writing the
# package.xml the real one leaves. Run: tests/test-android-sdk.sh

set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_FOLDER="loadouts/private_dot_config/.android-sdk"
# Bun itself, not mise's shim: the scripts run with a bare PATH.
BUN="$(bun -e 'console.log(process.execPath)')" || { echo "bun not found"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf -- "${WORK:?}"' EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
skip() { echo "  skip - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])"; }
not_contains() { [[ "$1" != *"$2"* ]] && ok "$3" || bad "$3 (expected NOT to contain [$2], got [$1])"; }

# A real Android Studio outside $HOME is found whatever the fixture says.
real_studio=0
for d in "/Applications/Android Studio.app/Contents/jbr/Contents/Home" /opt/android-studio/jbr; do
  [[ -x "$d/bin/java" ]] && real_studio=1
done

# fixture <name> [sdk] [studio] [sdkmanager]: a case directory with the repo
# copy and an empty pins file, and whichever of the three it names. A
# needs-keychain file in it makes sdkmanager's downloads fail, as behind a TLS
# proxy, unless it trusts the login keychain.
fixture() {
  F="$WORK/$1"
  shift
  HOME_DIR="$F/home"
  SDK="$HOME_DIR/Library/Android/Sdk"
  JDK="$HOME_DIR/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  LOG="$F/sdkmanager.log"
  LIST="$F/sdkmanager.list"
  R="$F/repo"
  PINS="$R/$SDK_FOLDER/.loadout/packages"
  mkdir -p "$HOME_DIR" "$R/lib" "$R/loadouts/private_dot_config" "$R/loadouts/private_dot_local/lib"
  cp "$REPO/package.json" "$R/"
  cp "$REPO/lib/loadout.ts" "$R/lib/"
  cp -R "$REPO/$SDK_FOLDER" "$R/loadouts/private_dot_config/"
  cp "$REPO/loadouts/private_dot_local/lib/android-sdk-dir.sh" "$R/loadouts/private_dot_local/lib/"
  : >"$PINS"
  : >"$LOG"
  : >"$LIST"
  local part
  for part in "$@"; do
    case "$part" in
    sdk) mkdir -p "$SDK" ;;
    studio)
      mkdir -p "$JDK/bin"
      printf '#!/bin/sh\necho '\''openjdk version "25.0.2" 2026-01-20'\'' >&2\n' >"$JDK/bin/java"
      chmod +x "$JDK/bin/java"
      ;;
    sdkmanager)
      mkdir -p "$SDK/cmdline-tools/latest/bin"
      cat >"$SDK/cmdline-tools/latest/bin/sdkmanager" <<'EOF'
#!/bin/sh
echo "JAVA_HOME=$JAVA_HOME OPTS=${SDKMANAGER_OPTS:-} ARGS=$*" >>"$LOG"
root=
list=0
for a; do
  case $a in
  --sdk_root=*) root=${a#*=} ;;
  --list) list=1 ;;
  esac
done
case "${SDKMANAGER_OPTS:-}" in
*trustStoreType=KeychainStore) ;;
*)
  if [ -e "$(dirname "$LOG")/needs-keychain" ]; then
    echo "Warning: Failed to download any source lists!" >&2
    [ "$list" = 1 ] && exit 0
    exit 1
  fi
  ;;
esac
if [ "$list" = 1 ]; then cat "$LIST"; exit 0; fi
for a; do
  case $a in
  --*) ;;
  *) d="$root/$(printf '%s' "$a" | tr ';' '/')"; mkdir -p "$d"; touch "$d/package.xml" ;;
  esac
done
EOF
      chmod +x "$SDK/cmdline-tools/latest/bin/sdkmanager"
      ;;
    esac
  done
}

# have <id>...: packages already in the fixture's SDK.
have() {
  local id d
  for id; do
    d="$SDK/$(printf '%s' "$id" | tr ';' '/')"
    mkdir -p "$d"
    touch "$d/package.xml"
  done
}

pin() { printf '%s\n' "$@" >>"$PINS"; }

# run <script> [args]: the fixture's copy, as loadout runs it, stdout+stderr;
# the exit code lands in $rc.
run() {
  local script="$1"
  shift
  out=$(HOME="$HOME_DIR" LOADOUT_REPO="$R" LOG="$LOG" LIST="$LIST" PATH="/usr/bin:/bin" \
    "$BUN" "$R/$SDK_FOLDER/.loadout/$script" "$@" 2>&1)
  rc=$?
}

### check ###
echo "check"

fixture no-sdk studio
pin "build-tools;36.0.0"
run sdk.ts check
eq "$rc" 1 "fails without an SDK directory"
contains "$out" "install Android Studio" "says to install Android Studio"

fixture all-present sdk studio sdkmanager
pin "# a comment" "" "build-tools;36.0.0  # trailing comment" "platforms;android-36" "platform-tools"
have "build-tools;36.0.0" "platforms;android-36" "platform-tools"
run sdk.ts check
eq "$rc" 0 "passes when every pin is installed, comments and blank lines ignored"
eq "$(cat "$LOG")" "" "never starts sdkmanager to check"

fixture extra-installed sdk studio sdkmanager
pin "build-tools;36.0.0"
have "build-tools;36.0.0" "build-tools;37.0.0"
run sdk.ts check
eq "$rc" 0 "passes with versions Studio installed on top"

fixture one-missing sdk studio sdkmanager
pin "build-tools;36.0.0" "platform-tools"
have "platform-tools"
run sdk.ts check
eq "$rc" 1 "fails when a pin is missing"
contains "$out" "missing: build-tools;36.0.0" "names the missing pin"
not_contains "$out" "missing: platform-tools" "doesn't name the installed one"

fixture missing-no-tools sdk studio
pin "build-tools;36.0.0"
run sdk.ts check
eq "$rc" 1 "fails when a pin is missing and there's no sdkmanager"
contains "$out" "Android SDK Command-line Tools (latest)" "says where Studio installs sdkmanager"

### install ###
echo "install"

fixture install sdk studio sdkmanager
pin "build-tools;36.0.0" "platforms;android-36" "platform-tools"
have "platform-tools"
run sdk.ts install
eq "$rc" 0 "installs"
contains "$(cat "$LOG")" "ARGS=--sdk_root=$SDK build-tools;36.0.0 platforms;android-36" \
  "passes only the missing pins, into the SDK Studio manages"
not_contains "$(cat "$LOG")" "platform-tools" "leaves the installed pin alone"
contains "$(cat "$LOG")" "JAVA_HOME=$JDK " "runs sdkmanager on Android Studio's bundled JDK"
run sdk.ts check
eq "$rc" 0 "check passes afterwards"

not_contains "$(cat "$LOG")" "KeychainStore" "the JDK's own cacerts first, when they're enough"

fixture install-behind-proxy sdk studio sdkmanager
touch "$F/needs-keychain"
pin "build-tools;36.0.0"
run sdk.ts install
if [[ "$(uname -s)" == Darwin ]]; then
  eq "$rc" 0 "behind a TLS proxy on macOS, installs"
  eq "$(grep -c ARGS= "$LOG")" 2 "after one failed try"
  contains "$(tail -n 1 "$LOG")" "OPTS=-Djavax.net.ssl.trustStoreType=KeychainStore " \
    "retrying with the login keychain, where the proxy's root lives"
  contains "$out" "retrying with the login keychain" "says why it runs sdkmanager twice"
else
  eq "$rc" 1 "behind a TLS proxy off macOS, fails"
  not_contains "$(cat "$LOG")" "KeychainStore" "with no keychain to retry with"
fi

fixture install-nothing sdk studio sdkmanager
pin "platform-tools"
have "platform-tools"
run sdk.ts install
eq "$rc" 0 "nothing to install succeeds"
eq "$(cat "$LOG")" "" "without starting sdkmanager"

fixture install-no-tools sdk studio
pin "build-tools;36.0.0"
run sdk.ts install
eq "$rc" 1 "refuses to install without sdkmanager"
contains "$out" "SDK Tools" "says to add the Command-line Tools in Studio"

fixture install-no-studio sdk sdkmanager
pin "build-tools;36.0.0"
if ((real_studio)); then
  skip "refuses to install without Android Studio: this machine has one outside \$HOME"
else
  run sdk.ts install
  eq "$rc" 1 "refuses to install without Android Studio"
  contains "$out" "Android Studio not found" "says Android Studio is missing"
  eq "$(cat "$LOG")" "" "without starting sdkmanager"
fi

### outdated ###
echo "outdated"

fixture outdated sdk studio sdkmanager
pin "# build tools" "build-tools;36.0.0" "build-tools;35.0.0" "platforms;android-36" "platform-tools" "ndk;27.0.12077973"
cat >"$LIST" <<'EOF'
Installed packages:
  Path                 | Version | Description
  -------              | ------- | -------
  build-tools;36.0.0   | 36.0.0  | Android SDK Build-Tools 36
Available Packages:
  Path                 | Version | Description
  -------              | ------- | -------
  build-tools;3.0.0    | 3.0.0   | Android SDK Build-Tools 3
  build-tools;35.0.1   | 35.0.1  | Android SDK Build-Tools 35.0.1
  build-tools;36.0.0   | 36.0.0  | Android SDK Build-Tools 36
  build-tools;36.1.0   | 36.1.0  | Android SDK Build-Tools 36.1
  build-tools;36.10.0  | 36.10.0 | Android SDK Build-Tools 36.10
  build-tools;36.11.0-rc1 | 36.11.0 rc1 | Android SDK Build-Tools 36.11-rc1
  build-tools;37.0.0   | 37.0.0  | Android SDK Build-Tools 37
  ndk;27.0.12077973    | 27.0.12077973 | NDK
  platforms;android-37 | 1       | Android SDK Platform 37
EOF
run outdated-sdk.ts
eq "$rc" 0 "lists"
eq "$out" "build-tools 36.0.0 36.10.0" \
  "one row, for the first build-tools pin, at the newest stable 36.x, version-sorted, not 37"

run outdated-sdk.ts update build-tools
eq "$rc" 0 "updates"
contains "$(cat "$LOG")" "ARGS=--sdk_root=$SDK build-tools;36.10.0" "installs the newest on the line"
eq "$(cat "$PINS")" "$(printf '%s\n' "# build tools" "build-tools;36.10.0" "build-tools;35.0.0" \
  "platforms;android-36" "platform-tools" "ndk;27.0.12077973")" \
  "rewrites only that pin, comments and the other build-tools pin kept"
run outdated-sdk.ts update build-tools
contains "$out" "already pinned to 36.10.0" "a second update has nothing to do"

if [[ "$(uname -s)" == Darwin ]]; then
  cp "$LIST" "$WORK/list"
  fixture outdated-behind-proxy sdk studio sdkmanager
  touch "$F/needs-keychain"
  cp "$WORK/list" "$LIST"
  pin "build-tools;36.0.0"
  run outdated-sdk.ts
  eq "$out" "build-tools 36.0.0 36.10.0" "behind a TLS proxy on macOS, lists through the login keychain"
fi

fixture outdated-no-tools sdk studio
pin "build-tools;36.0.0"
run outdated-sdk.ts
eq "$rc" 0 "without sdkmanager, exits 0 (loadout reads non-zero as a failure)"
eq "$out" "" "and says nothing"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
