#!/usr/bin/env bash
source "$HOME/.config/sketchybar/env.sh"
sketchybar --set "$NAME" label="$(/bin/date '+%a %-d %b  %H:%M')"
