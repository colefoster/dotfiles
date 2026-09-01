# Console — a TUI, not a UI. Nothing is a shape: no backgrounds, no radius, no
# blur. Items are separated by rules, the way a status line is. Green-on-black
# is a cliché, so this is bone-on-charcoal with amber for what has focus.
NAME="Console"
DECK=0xff0c0c0c; PANEL=0xff141414; LINE=0xff2e2e2e
INK=0xffd8d2c4;  DIM=0xff8b857a;   FAINT=0xff4f4a43
AMBER=0xffe8b04b; CYAN=0xff8fa876; GOOD=0xff8fa876; BAD=0xffc4614e

BAR_HEIGHT=26; BAR_MARGIN=0;  BAR_RADIUS=0;  BAR_PADDING=8;  BAR_BLUR=0;  BAR_YOFF=0
ITEM_RADIUS=0; ITEM_HEIGHT=18; ITEM_BG=off;   FONT_SIZE=12
PIP_STYLE=underline
CHROME=text          # chips | text | outline
ITEM_OUTLINE=0
SEP_STYLE=pipe       # none | pipe

BORDER_WIDTH=1.0; BORDER_STYLE=square; BORDER_INACTIVE=on

GAP_INNER=0; GAP_OUTER=0; GAP_TOP_BUILTIN=0; GAP_TOP_EXTERNAL=28
ACCORDION_PADDING=14
