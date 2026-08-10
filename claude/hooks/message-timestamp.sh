#!/bin/bash
# UserPromptSubmit hook: emits current local time + gap since previous message.
# Stdout is injected into Claude's context.
# Timezone: relies on system /etc/localtime — does NOT set TZ.

set -u
unset TZ  # guarantee system local time, never a stale env override

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID="default"

mkdir -p "$HOME/.claude/state"
STATE_FILE="$HOME/.claude/state/last-message-ts-$SESSION_ID"
DATE_FILE="$HOME/.claude/state/last-message-date-$SESSION_ID"

NOW_EPOCH=$(date +%s)
NOW_DATE=$(date '+%Y-%m-%d')
NOW_TIME=$(date '+%H:%M %Z')

GAP_STR=""
if [ -f "$STATE_FILE" ]; then
  LAST=$(cat "$STATE_FILE" 2>/dev/null || echo "")
  if [ -n "$LAST" ] && [ "$LAST" -gt 0 ] 2>/dev/null; then
    DIFF=$(( NOW_EPOCH - LAST ))
    if   [ "$DIFF" -lt 300 ];     then GAP_STR=""                                    # <5min: skip
    elif [ "$DIFF" -lt 3600 ];    then GAP_STR=", $(( DIFF / 60 ))m since last msg"
    elif [ "$DIFF" -lt 86400 ];   then GAP_STR=", $(( DIFF / 3600 ))h $(( (DIFF % 3600) / 60 ))m since last msg"
    else                               GAP_STR=", $(( DIFF / 86400 ))d $(( (DIFF % 86400) / 3600 ))h since last msg"
    fi
  fi
fi

LAST_DATE=""
[ -f "$DATE_FILE" ] && LAST_DATE=$(cat "$DATE_FILE" 2>/dev/null || echo "")

if [ "$NOW_DATE" = "$LAST_DATE" ]; then
  STAMP="$NOW_TIME"
else
  STAMP="$(date '+%a %Y-%m-%d') $NOW_TIME"
fi

echo "$NOW_EPOCH" > "$STATE_FILE"
echo "$NOW_DATE"  > "$DATE_FILE"
echo "[user message at $STAMP$GAP_STR]"
