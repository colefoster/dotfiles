#!/usr/bin/env bash
# Mullion — the active style. Colour AND geometry, in one place.
# Sourced by SketchyBar and JankyBorders; the gap numbers are pushed into
# aerospace.toml by `mull theme`. Nothing here changes what a key does.
#
#   mull theme            list styles
#   mull theme nord       switch
#
# The active choice is one word in ./active.

MULLION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ACTIVE="$(cat "$MULLION_DIR/active" 2>/dev/null || echo deck)"
[ -r "$MULLION_DIR/styles/$ACTIVE.sh" ] || ACTIVE=deck
. "$MULLION_DIR/styles/$ACTIVE.sh"

export STYLE_NAME="${NAME:-$ACTIVE}" STYLE_ID="$ACTIVE"
export DECK PANEL LINE INK DIM FAINT AMBER CYAN GOOD BAD
export BAR_HEIGHT BAR_MARGIN BAR_RADIUS BAR_PADDING BAR_BLUR BAR_YOFF
export ITEM_RADIUS ITEM_HEIGHT ITEM_BG FONT_SIZE PIP_STYLE
export BORDER_WIDTH BORDER_STYLE BORDER_INACTIVE
export GAP_INNER GAP_OUTER GAP_TOP_BUILTIN GAP_TOP_EXTERNAL ACCORDION_PADDING

# The one thing every style shares: you only have the one font installed.
export FONT="FiraCode Nerd Font"

# Back-compat for anything still reading the old names.
export THEME_NAME="$STYLE_NAME" THEME_ID="$STYLE_ID"
