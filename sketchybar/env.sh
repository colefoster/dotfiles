#!/usr/bin/env bash
# Sourced by sketchybarrc and every plugin.
# SketchyBar spawns plugins with a bare PATH, so pin the tools they need.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# The look lives in one place, shared with JankyBorders.
source "$HOME/.config/mullion/style.sh"
