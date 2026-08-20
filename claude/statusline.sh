#!/bin/bash
# Claude Code status line — one compact line
input=$(cat)

IFS=$'\t' read -r MODEL PCT DIR <<< \
  "$(echo "$input" | jq -r '[
    (.model.display_name // .model.id // "?"),
    ((.context_window.used_percentage // 0) | floor),
    (.workspace.current_dir // "")
  ] | map(tostring) | join("\t")')"

PCT=${PCT:-0}
MODEL=${MODEL:-?}

G="\033[32m"; Y="\033[33m"; R="\033[31m"; C="\033[36m"; D="\033[90m"; M="\033[35m"; B="\033[1m"; RST="\033[0m"

if [ "$PCT" -ge 80 ]; then PCT_CLR="$R"
elif [ "$PCT" -ge 50 ]; then PCT_CLR="$Y"
else PCT_CLR="$G"; fi

# Git (cached per-directory, refreshed every 5s)
CACHE="/tmp/claude-statusline-git-$(echo "$DIR" | md5sum 2>/dev/null | cut -c1-8 || echo "x")"
GIT=""
if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  if [ ! -f "$CACHE" ] || [ $(($(date +%s) - $(stat -f %m "$CACHE" 2>/dev/null || stat -c %Y "$CACHE" 2>/dev/null || echo 0))) -gt 5 ]; then
    BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
    DIRTY=$(git -C "$DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    printf '%s|%s\n' "$BRANCH" "$DIRTY" > "$CACHE"
  fi
  IFS='|' read -r BRANCH DIRTY < "$CACHE"
  # Long ticket-style branches blow out the line; keep the head of the name.
  [ "${#BRANCH}" -gt 24 ] && BRANCH="${BRANCH:0:23}…"
  [ -n "$BRANCH" ] && GIT="  ${D}⎇${RST} ${BRANCH}"
  [ "${DIRTY:-0}" -gt 0 ] && GIT="${GIT} ${Y}~${DIRTY}${RST}"
fi

ACCT=""
case "${CLAUDE_ACCOUNT_LABEL:-}" in
  "") ;;
  Personal) ACCT="${D}${CLAUDE_ACCOUNT_LABEL}${RST}  " ;;
  *) ACCT="${M}${B}${CLAUDE_ACCOUNT_LABEL}${RST}  " ;;
esac

printf '%b\n' "${ACCT}${C}${B}${MODEL}${RST}  ${PCT_CLR}${PCT}%${RST}  ${DIR##*/}${GIT}"
