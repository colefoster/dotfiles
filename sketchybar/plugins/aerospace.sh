#!/usr/bin/env bash
# One workspace pip. $NAME is "space.<n>"; $FOCUSED_WORKSPACE arrives with the
# aerospace_workspace_change event and is empty on the other triggers.
#
# Two style decisions land here:
#   PIP_MODE   number  the workspace number
#              icons   a glyph per app living in it, so you learn the shape
#   PIP_STYLE  how the focused one is marked: chip / underline / dot
source "$HOME/.config/sketchybar/env.sh"
source "$HOME/.config/sketchybar/icons.sh"

sid="${NAME#space.}"
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
apps="$(aerospace list-windows --workspace "$sid" --format '%{app-name}' 2>/dev/null || true)"
count="$(printf '%s' "$apps" | grep -c . || true)"
[ -z "$count" ] && count=0

# Empty workspaces can disappear entirely rather than sit there as dead numbers.
if [ "$count" -eq 0 ] && [ "$HIDE_EMPTY" = "on" ] && [ "$sid" != "$focused" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi
sketchybar --set "$NAME" drawing=on

if [ "$PIP_FORM" = "bracket" ]; then
  # A status line, not a row of buttons: [1:gh zd]
  short=""
  seen=""
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    case " $seen " in *" $app "*) continue ;; esac
    seen="$seen $app"
    short="$short$(printf '%s' "$app" | tr '[:upper:]' '[:lower:]' | cut -c1-2) "
  done <<EOF
$apps
EOF
  if [ -n "$short" ]; then
    sketchybar --set "$NAME" icon="[$sid:" label="${short% }]" label.drawing=on
  else
    sketchybar --set "$NAME" icon="[$sid" label="]" label.drawing=on
  fi
elif [ "$PIP_MODE" = "icons" ] && [ "$count" -gt 0 ]; then
  # one glyph per distinct app, in tree order
  glyphs=""
  seen=""
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    case " $seen " in *" $app "*) continue ;; esac
    seen="$seen $app"
    glyphs="$glyphs$(app_icon "$app") "
  done <<EOF
$apps
EOF
  sketchybar --set "$NAME" icon="$sid" label="${glyphs% }" label.drawing=on
else
  sketchybar --set "$NAME" icon="$sid" label.drawing=off
fi

# reset the decorations this style doesn't use
sketchybar --set "$NAME" background.drawing=off background.border_width=0 \
                         background.height="$ITEM_HEIGHT" background.y_offset=0

if [ "$sid" = "$focused" ]; then
  case "$PIP_STYLE" in
    underline)
      sketchybar --set "$NAME" icon.color="$AMBER" label.color="$AMBER" \
        background.drawing=on background.color=0x00000000 \
        background.border_color="$AMBER" background.border_width=2 \
        background.height=2 background.y_offset=-10
      ;;
    dot)
      sketchybar --set "$NAME" icon.color="$AMBER" label.color="$AMBER"
      ;;
    *)
      if [ "$ITEM_BG" = "on" ]; then
        sketchybar --set "$NAME" icon.color="$AMBER" label.color="$AMBER" \
          background.drawing=on background.color="$PANEL"
      else
        sketchybar --set "$NAME" icon.color="$AMBER" label.color="$AMBER"
      fi
      ;;
  esac
elif [ "$count" -gt 0 ]; then
  sketchybar --set "$NAME" icon.color="$INK" label.color="$DIM"
else
  sketchybar --set "$NAME" icon.color="$FAINT" label.color="$FAINT"
fi
