# Sourced by the scripts that talk to the Omarchy shell over IPC (omarchy-shell,
# and `omarchy plugin …`, which goes through it). omarchy-shell gives each call
# OMARCHY_SHELL_IPC_TIMEOUT, 2s by default, and the shell can take longer while
# it hot-reloads plugins or restarts — omarchy-bar-icons restarts it after
# rebuilding widgets — so a script run right after reads "omarchy-shell is not
# responding", or a plugin as not enabled. Calls get 10s here, and
# shell_ready waits (up to 30s) until the shell answers at all.
# shell_ready <mode>: a `check` asks once and gives up at once: with no shell
# running (logged out, over ssh) every status would otherwise stall 30s per
# script. The waiting is for installs, which run right after a restart.

export OMARCHY_SHELL_IPC_TIMEOUT=${OMARCHY_SHELL_IPC_TIMEOUT:-10s}

shell_ready() {
  tries=0
  max=30
  [ "${1:-install}" = check ] && max=1
  until omarchy-shell shell ping >/dev/null 2>&1; do
    tries=$((tries + 1))
    [ "$tries" -lt "$max" ] || { echo "omarchy-shell isn't answering" >&2; return 1; }
    sleep 1
  done
}
