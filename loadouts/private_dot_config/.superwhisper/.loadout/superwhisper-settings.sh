#!/bin/sh
# Superwhisper's settings, set through its own CLI (`superwhisper models …`,
# `superwhisper general set …`), never by editing its files: the CLI validates
# each value, refuses to overwrite a change made elsewhere, and applies it at
# once. One key=value per argument:
#   processing=<mode>  cloud, offline or offline_lite. An offline mode's
#                      models (Superwhisper lists what each mode is missing:
#                      `models show`, processingModes) are downloaded first,
#                      one at a time, as Superwhisper only runs one download.
#   <key>=<value>      a general setting with a string value (language, tone),
#                      set after the mode: a language must be one the mode
#                      supports.
# Done = the mode is selected with none of its models missing, and every
# setting has its value.
# usage: superwhisper-settings.sh [check] key=value...
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
[ $# -gt 0 ] || { echo "usage: $0 [check] key=value..." >&2; exit 2; }
for kv in "$@"; do
  case $kv in *=*) ;; *) echo "not key=value: $kv" >&2; exit 2 ;; esac
done

models() { superwhisper models show; }
general() { superwhisper general show; }

# The models <mode> still needs, one per line.
missing() {
  models | jq -r --arg m "$1" '.processingModes[] | select(.value == $m) | .missing[]'
}

# "<state> <partialBytes> <sizeBytes>" of one model.
progress() {
  models | jq -r --arg id "$1" '.models[] | select(.id == $id) | "\(.download.state) \(.partialBytes // 0) \(.sizeBytes // 0)"'
}

# Downloads one model and waits for it (up to an hour), saying how far it got
# once a minute: a large one takes a while, and a setup run shouldn't look stuck.
download() {
  tries=0
  while :; do
    set -- "$1" $(progress "$1")
    [ "$2" = installed ] && { echo "  $1: done"; return 0; }
    case $2 in
    missing | paused) superwhisper models download "$1" >/dev/null 2>&1 || true ;;
    esac
    if [ $((tries % 6)) -eq 0 ] && [ "${4:-0}" -gt 0 ]; then
      echo "  $1: $(($3 * 100 / $4))% of $(($4 / 1048576)) MB ($2, $((tries / 6))m)"
    fi
    tries=$((tries + 1))
    [ "$tries" -lt 360 ] || { echo "$1 didn't finish downloading" >&2; return 1; }
    sleep 10
  done
}

applied() {
  m=$(models) g=$(general)
  for kv in "$@"; do
    k=${kv%%=*} v=${kv#*=}
    if [ "$k" = processing ]; then
      [ "$(printf '%s' "$m" | jq -r .processing)" = "$v" ] || return 1
      [ -z "$(printf '%s' "$m" | jq -r --arg v "$v" '.processingModes[] | select(.value == $v) | .missing[]')" ] || return 1
    else
      [ "$(printf '%s' "$g" | jq -r --arg k "$k" '.config[$k] // empty')" = "$v" ] || return 1
    fi
  done
}

case "$MODE" in
check)
  command -v superwhisper >/dev/null 2>&1 || exit 1
  applied "$@"
  ;;
install)
  command -v superwhisper >/dev/null 2>&1 || { echo "superwhisper isn't installed (script.omarchy-default-dictation)" >&2; exit 1; }
  # The mode first: the other settings are checked against it.
  for kv in "$@"; do
    [ "${kv%%=*}" = processing ] || continue
    for model in $(missing "${kv#*=}"); do
      echo "downloading Superwhisper's $model model"
      download "$model"
    done
    superwhisper models select "${kv#*=}" >/dev/null
  done
  for kv in "$@"; do
    [ "${kv%%=*}" = processing ] && continue
    superwhisper general set "${kv%%=*}" "$(jq -cn --arg v "${kv#*=}" '$v')" >/dev/null
  done
  applied "$@" || { echo "Superwhisper's settings didn't take: $*" >&2; exit 1; }
  ;;
esac
