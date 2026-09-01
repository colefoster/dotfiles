#!/usr/bin/env bash
# Cheap enough for a 3s poll — `top -l 1` is not.
# In graph form the value is pushed as 0..1 and SketchyBar draws the sparkline.
source "$HOME/.config/sketchybar/env.sh"

cores="$(/usr/sbin/sysctl -n hw.logicalcpu)"
load="$(/bin/ps -A -o %cpu | /usr/bin/awk -v c="$cores" '{s+=$1} END {printf "%.0f", s/c}')"
[ -z "$load" ] && load=0

if [ "$CPU_FORM" = "graph" ]; then
  sketchybar --push "$NAME" "$(/usr/bin/awk -v l="$load" 'BEGIN{printf "%.3f", (l>100?100:l)/100}')"
  exit 0
fi

color="$DIM"
[ "$load" -ge 70 ] 2>/dev/null && color="$AMBER"
[ "$load" -ge 90 ] 2>/dev/null && color="$BAD"
sketchybar --set "$NAME" label="${load}%" label.color="$color"
