#!/usr/bin/env bash
# The whole look, in one place. Sourced by SketchyBar and JankyBorders.
# Nothing here changes how a single key behaves — this is appearance only.
#
# Switch themes with:  theme-set <name>     (theme-set with no args lists them)
# The active choice is one word in ./active.

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ACTIVE="$(cat "$THEME_DIR/active" 2>/dev/null || echo deck)"
[ -r "$THEME_DIR/palettes/$ACTIVE.sh" ] || ACTIVE=deck

# Palettes set colours only; everything else is shared, so a theme can never
# change a font or a border width out from under you.
. "$THEME_DIR/palettes/$ACTIVE.sh"

export THEME_NAME="${NAME:-$ACTIVE}"
export DECK PANEL LINE INK DIM FAINT AMBER CYAN GOOD BAD

# Shared across every theme — geometry and type, not colour.
export FONT="FiraCode Nerd Font"
export BORDER_WIDTH=5.0
export BORDER_STYLE=round
