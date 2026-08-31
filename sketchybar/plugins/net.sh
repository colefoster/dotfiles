#!/usr/bin/env bash
# Tailscale state. You live on it, and nothing else on the desktop surfaces
# whether you're actually on the tailnet or just on wifi.
source "$HOME/.config/sketchybar/env.sh"
TS=/Applications/Tailscale.app/Contents/MacOS/Tailscale
[ -x "$TS" ] || TS="$(command -v tailscale || true)"

if [ -z "$TS" ]; then
  sketchybar --set "$NAME" drawing=off; exit 0
fi

state="$("$TS" status --json 2>/dev/null | /usr/bin/python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: print("off"); raise SystemExit
if d.get("BackendState")!="Running": print("off"); raise SystemExit
exit_node = any(p.get("ExitNode") for p in (d.get("Peer") or {}).values())
print("exit" if exit_node else "on")
' 2>/dev/null || echo off)"

case "$state" in
  exit) icon=""; color="$AMBER"; label="exit" ;;
  on)   icon=""; color="$GOOD";  label="ts"   ;;
  *)    icon=""; color="$FAINT"; label="off"  ;;
esac
sketchybar --set "$NAME" drawing=on icon="$icon" icon.color="$color" \
                         label="$label" label.color="$DIM"
