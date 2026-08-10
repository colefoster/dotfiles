#!/bin/bash
# SessionStart hook: emits the current local day/date/time at session start.
# Timezone: relies on system /etc/localtime — does NOT set TZ.

unset TZ
echo "[session started $(date '+%A, %Y-%m-%d at %H:%M %Z')]"
