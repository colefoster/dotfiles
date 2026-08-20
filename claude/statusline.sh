#!/bin/bash
# Claude Code status line — info-dense two-liner
input=$(cat)

# Parse all fields in one jq call (values are \t-separated on one line)
IFS=$'\t' read -r MODEL PCT CTX_SIZE IN_TOK OUT_TOK CUR_IN CUR_OUT CACHE_READ CACHE_WRITE DIR VERSION <<< \
  "$(echo "$input" | jq -r '[
    (.model.display_name // .model.id // "?"),
    ((.context_window.used_percentage // 0) | floor),
    (.context_window.context_window_size // 0),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.current_usage.input_tokens // 0),
    (.context_window.current_usage.output_tokens // 0),
    ((.context_window.current_usage // {}).cache_read_input_tokens // 0),
    ((.context_window.current_usage // {}).cache_creation_input_tokens // 0),
    (.workspace.current_dir // ""),
    (.version // "?")
  ] | map(tostring) | join("\t")')"

# Default empty values to 0
PCT=${PCT:-0}; CTX_SIZE=${CTX_SIZE:-0}; IN_TOK=${IN_TOK:-0}; OUT_TOK=${OUT_TOK:-0}
CUR_IN=${CUR_IN:-0}; CUR_OUT=${CUR_OUT:-0}; CACHE_READ=${CACHE_READ:-0}; CACHE_WRITE=${CACHE_WRITE:-0}
MODEL=${MODEL:-?}; VERSION=${VERSION:-?}

# Colors
G="\033[32m"; Y="\033[33m"; R="\033[31m"; C="\033[36m"; D="\033[90m"; B="\033[1m"; RST="\033[0m"

# Context bar (15 segments)
BAR_W=15
FILLED=$((PCT * BAR_W / 100))
EMPTY=$((BAR_W - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

if [ "$PCT" -ge 80 ]; then BAR_CLR="$R"
elif [ "$PCT" -ge 50 ]; then BAR_CLR="$Y"
else BAR_CLR="$G"; fi

# Context window label
if [ "$CTX_SIZE" -ge 1000000 ]; then
  CTX_LABEL="1M"
elif [ "$CTX_SIZE" -gt 0 ]; then
  CTX_LABEL="$((CTX_SIZE / 1000))k"
else
  CTX_LABEL="?"
fi

# Format tokens compactly
fmt() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "$n / 1000000" | bc -l)"
  elif [ "$n" -ge 1000 ]; then
    printf "%.1fk" "$(echo "$n / 1000" | bc -l)"
  else
    echo "$n"
  fi
}

IN_FMT=$(fmt "$IN_TOK")
OUT_FMT=$(fmt "$OUT_TOK")
CUR_IN_FMT=$(fmt "$CUR_IN")
CUR_OUT_FMT=$(fmt "$CUR_OUT")
CACHE_R_FMT=$(fmt "$CACHE_READ")
CACHE_W_FMT=$(fmt "$CACHE_WRITE")

# Git (cached per-directory, refreshed every 5s)
CACHE="/tmp/claude-statusline-git-$(echo "$DIR" | md5sum 2>/dev/null | cut -c1-8 || echo "x")"
BRANCH=""; GIT_INFO=""
if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  if [ ! -f "$CACHE" ] || [ $(($(date +%s) - $(stat -f %m "$CACHE" 2>/dev/null || stat -c %Y "$CACHE" 2>/dev/null || echo 0))) -gt 5 ]; then
    BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
    STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git -C "$DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    printf '%s|%s|%s|%s\n' "$BRANCH" "$STAGED" "$MODIFIED" "$UNTRACKED" > "$CACHE"
  fi
  IFS='|' read -r BRANCH STAGED MODIFIED UNTRACKED < "$CACHE"
  [ "$STAGED" -gt 0 ]   && GIT_INFO="${G}+${STAGED}${RST} "
  [ "$MODIFIED" -gt 0 ] && GIT_INFO="${GIT_INFO}${Y}~${MODIFIED}${RST} "
  [ "$UNTRACKED" -gt 0 ] && GIT_INFO="${GIT_INFO}${D}?${UNTRACKED}${RST}"
fi

# Line 1: model, context size, folder, git, version
ACCT=""
case "${CLAUDE_ACCOUNT_LABEL:-}" in
  "") ;;
  Personal) ACCT="${D}${CLAUDE_ACCOUNT_LABEL}${RST}  " ;;
  *) ACCT="\033[35m${B}${CLAUDE_ACCOUNT_LABEL}${RST}  " ;;
esac

LINE1="${ACCT}${C}${B}${MODEL}${RST} ${D}(${CTX_LABEL})${RST}  ${DIR##*/}"
[ -n "$BRANCH" ] && LINE1="${LINE1}  ${D}on${RST} ${BRANCH} ${GIT_INFO}"
LINE1="${LINE1}  ${D}v${VERSION}${RST}"

# Line 2: context bar, cumulative tokens, current turn tokens, cache
LINE2="${BAR_CLR}${BAR}${RST} ${PCT}%"
LINE2="${LINE2}  ${D}tokens${RST} ${IN_FMT}/${OUT_FMT} ${D}turn${RST} ${CUR_IN_FMT}/${CUR_OUT_FMT} ${D}cache${RST} ${CACHE_R_FMT}r/${CACHE_W_FMT}w"

printf '%b\n' "$LINE1"
printf '%b\n' "$LINE2"
