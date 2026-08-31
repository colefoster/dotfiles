#!/usr/bin/env bash
# Cheap enough for every 5s — `top -l 1` is not.
source "$HOME/.config/sketchybar/env.sh"

cores="$(/usr/sbin/sysctl -n hw.logicalcpu)"
load="$(/bin/ps -A -o %cpu | /usr/bin/awk -v c="$cores" '{s+=$1} END {printf "%.0f", s/c}')"
[ -z "$load" ] && load=0

color="$DIM"
[ "$load" -ge 70 ] 2>/dev/null && color="$AMBER"
[ "$load" -ge 90 ] 2>/dev/null && color="$BAD"
sketchybar --set "$NAME" label="${load}%" label.color="$color"
