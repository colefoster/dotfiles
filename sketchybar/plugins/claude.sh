#!/usr/bin/env bash
# How many Claude sessions are alive right now, across both accounts.
# cc-sessions already knows; this just counts its rows.
source "$HOME/.config/sketchybar/env.sh"
CC="$HOME/dotfiles/zsh/common/cc-sessions"

n=0
if [ -x "$CC" ]; then
  n="$(CC_CWD=$HOME "$CC" 2>/dev/null | grep -c 'open' || true)"
fi
[ -z "$n" ] && n=0

if [ "$n" -eq 0 ]; then
  sketchybar --set "$NAME" icon="" icon.color="$FAINT" label="$n" label.color="$FAINT"
else
  sketchybar --set "$NAME" icon="" icon.color="$CYAN" label="$n" label.color="$DIM"
fi
