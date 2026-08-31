#!/usr/bin/env bash
source "$HOME/.config/sketchybar/env.sh"
[ "$SENDER" = "front_app_switched" ] && sketchybar --set "$NAME" label="$INFO"
