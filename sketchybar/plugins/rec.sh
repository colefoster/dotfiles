#!/usr/bin/env bash
# Lit while the camera is in use, so a bar that replaces the menu bar doesn't
# also hide macOS's recording dot.
#
# Camera only. The obvious mic check (`log show --predicate coreaudio`) costs
# ~0.7s per run, which is far too much to spawn on a timer — macOS exposes no
# cheap public way to ask "is the microphone live". The orange dot in the
# system menu bar remains the honest answer for mic.
source "$HOME/.config/sketchybar/env.sh"

if /usr/sbin/ioreg -c AppleCameraInterface -r -d 1 2>/dev/null \
   | grep -q '"VDCAssistant_Return_Status" = 0'; then
  sketchybar --set "$NAME" drawing=on icon="" icon.color="$BAD" label="cam" label.color="$BAD"
else
  sketchybar --set "$NAME" drawing=off
fi
