#!/bin/sh
# t2fanrd fan curve for the MacBookPro16,1 (T2).
#
# The t2fanrd rpm ships no config at all — it reads the original Python
# daemon's path, /etc/t2fand.conf, and writes a default there if absent. So
# this file is entirely ours; keeping it in the repo is the only record of
# what the fan curve is supposed to be. (On Omarchy the installer writes its
# own linear 55-75 default there once, at install; this replaces it.)
#
# low/high are the ends of the ramp: below low_temp the fan sits at its
# hardware minimum, above high_temp at its maximum. The min/max RPM come from
# applesmc and differ per fan (Fan1 1836-5616, Fan2 1700-5200) — they are not
# configurable here. speed_curve is one of linear|exponential|logarithmic;
# exponential ramps slowest at the bottom of the band.
#
# Linear 60-80. This Mac idles at 60-70 C (an i9 next to an awake AMD dGPU),
# so the band starts at 60 to keep the fans near their minimum there, and
# ends at 80 to reach full speed well before the CPU's 100 C limit. It was
# exponential 55-85, which stayed near the minimum until ~75 C and then
# ramped late and hard: once t2fanrd could read the GPU temperature
# (t2-fan-gpu-card), the package throttled about 70 times a minute. Omarchy's
# linear 55-75 throttles less but runs ~3700 RPM at a 65 C idle.
#
# t2fanrd reads this only at startup, hence the restart in install.
set -eu

CONF=/etc/t2fand.conf
WANT='[Fan1]
low_temp=60
high_temp=80
speed_curve=linear
always_full_speed=false

[Fan2]
low_temp=60
high_temp=80
speed_curve=linear
always_full_speed=false'

case "${1:-install}" in
  check)
    [ "$(cat "$CONF" 2>/dev/null)" = "$WANT" ]
    ;;
  install)
    if [ "$(cat "$CONF" 2>/dev/null)" != "$WANT" ]; then
      printf '%s\n' "$WANT" | sudo tee "$CONF" >/dev/null
      sudo systemctl restart t2fanrd
    fi
    ;;
  *) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
