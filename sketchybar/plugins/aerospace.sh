#!/usr/bin/env bash
# One workspace pip. $NAME is "space.<n>"; $FOCUSED_WORKSPACE arrives with the
# aerospace_workspace_change event and is empty on the other triggers.
#
# How the focused one is marked is a style decision:
#   chip       filled rounded background behind the number
#   underline  a coloured rule under it, background off
#   dot        the number recoloured, no background at all
source "$HOME/.config/sketchybar/env.sh"

sid="${NAME#space.}"
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
count="$(aerospace list-windows --workspace "$sid" --count 2>/dev/null || echo 0)"
[ -z "$count" ] && count=0

# reset the decorations this style doesn't use
sketchybar --set "$NAME" background.drawing=off \
                         background.border_width=0 \
                         background.height="$ITEM_HEIGHT"

if [ "$sid" = "$focused" ]; then
  case "$PIP_STYLE" in
    underline)
      sketchybar --set "$NAME" icon.color="$AMBER" \
        background.drawing=on background.color=0x00000000 \
        background.border_color="$AMBER" background.border_width=2 \
        background.height=2 background.y_offset=-10
      ;;
    dot)
      sketchybar --set "$NAME" icon.color="$AMBER"
      ;;
    *)
      [ "$ITEM_BG" = "on" ] \
        && sketchybar --set "$NAME" icon.color="$AMBER" \
             background.drawing=on background.color="$PANEL" background.y_offset=0 \
        || sketchybar --set "$NAME" icon.color="$AMBER"
      ;;
  esac
elif [ "$count" -gt 0 ]; then
  sketchybar --set "$NAME" icon.color="$INK"
else
  sketchybar --set "$NAME" icon.color="$FAINT"
fi
