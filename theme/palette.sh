#!/usr/bin/env bash
# The whole look — colour AND geometry — in one place. Sourced by SketchyBar
# and JankyBorders; the gap numbers are pushed into aerospace.toml by theme-set.
# Nothing here changes what a key does.
#
#   theme-set            list styles
#   theme-set nord       switch
#
# The active choice is one word in ./active.

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ACTIVE="$(cat "$THEME_DIR/active" 2>/dev/null || echo deck)"
[ -r "$THEME_DIR/styles/$ACTIVE.sh" ] || ACTIVE=deck
. "$THEME_DIR/styles/$ACTIVE.sh"

export THEME_NAME="${NAME:-$ACTIVE}" THEME_ID="$ACTIVE"
export DECK PANEL LINE INK DIM FAINT AMBER CYAN GOOD BAD
export BAR_HEIGHT BAR_MARGIN BAR_RADIUS BAR_PADDING BAR_BLUR BAR_YOFF
export ITEM_RADIUS ITEM_HEIGHT ITEM_BG FONT_SIZE PIP_STYLE
export BORDER_WIDTH BORDER_STYLE BORDER_INACTIVE
export GAP_INNER GAP_OUTER GAP_TOP_BUILTIN GAP_TOP_EXTERNAL ACCORDION_PADDING

# The one thing every style shares: you only have the one font installed.
export FONT="FiraCode Nerd Font"
