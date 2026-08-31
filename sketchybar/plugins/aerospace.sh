#!/usr/bin/env bash
# One workspace pip. $NAME is "space.<n>"; $FOCUSED_WORKSPACE arrives with the
# aerospace_workspace_change event and is empty on the other triggers.
source "$HOME/.config/sketchybar/env.sh"

sid="${NAME#space.}"
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
count="$(aerospace list-windows --workspace "$sid" --count 2>/dev/null || echo 0)"
[ -z "$count" ] && count=0

if [ "$sid" = "$focused" ]; then
  sketchybar --set "$NAME" background.drawing=on background.color="$PANEL" icon.color="$AMBER"
elif [ "$count" -gt 0 ]; then
  sketchybar --set "$NAME" background.drawing=off icon.color="$INK"
else
  sketchybar --set "$NAME" background.drawing=off icon.color="$FAINT"
fi
