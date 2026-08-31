#!/usr/bin/env bash
source "$HOME/.config/sketchybar/env.sh"

batt="$(/usr/bin/pmset -g batt)"
# BSD grep has no \d, and macOS ships bash 3.2 with no printf '\U' — so the
# glyphs below are literal Nerd Font characters, not escapes.
pct="$(printf '%s' "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
[ -z "$pct" ] && exit 0

if printf '%s' "$batt" | grep -q 'AC Power'; then icon="󰂄"; color="$GOOD"
elif [ "$pct" -ge 80 ]; then icon="󰁹"; color="$INK"
elif [ "$pct" -ge 50 ]; then icon="󰁿"; color="$INK"
elif [ "$pct" -ge 20 ]; then icon="󰁽"; color="$AMBER"
else                         icon="󰁺"; color="$BAD"
fi

sketchybar --set "$NAME" icon="$icon" icon.color="$color" \
                         label="${pct}%" label.color="$DIM"
