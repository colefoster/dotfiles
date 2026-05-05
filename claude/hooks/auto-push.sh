#!/usr/bin/env bash
# Auto-commit & push after Claude writes/edits files.
# Runs as a PostToolUse hook — receives JSON on stdin.
#
# Logic:
#   1. Read the edited file path from stdin
#   2. Find the git root (or init + create private GitHub repo)
#   3. Stage, commit, push
#
# Stays silent on success (no stdout = no blocking).
# Logs to ~/.claude/hooks/auto-push.log for debugging.

set -euo pipefail

LOG="$HOME/.claude/hooks/auto-push.log"
exec 2>>"$LOG"  # stderr -> log

# Parse stdin JSON
INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')"

if [[ -z "$FILE_PATH" ]]; then
  echo "[$(date)] No file_path in input, skipping" >&2
  exit 0
fi

# Skip files outside of project dirs (e.g. /tmp, dotfiles, claude config)
# Only auto-push for files under ~/dev or ~/projects
ALLOWED_PREFIXES=("$HOME/dev" "$HOME/projects" "$HOME/code")
ALLOWED=false
for prefix in "${ALLOWED_PREFIXES[@]}"; do
  if [[ "$FILE_PATH" == "$prefix"/* ]]; then
    ALLOWED=true
    break
  fi
done

if [[ "$ALLOWED" != "true" ]]; then
  echo "[$(date)] $FILE_PATH outside allowed dirs, skipping" >&2
  exit 0
fi

# Skip sensitive files
BASENAME="$(basename "$FILE_PATH")"
case "$BASENAME" in
  .env|.env.*|*.pem|*.key|credentials.json|secrets.*)
    echo "[$(date)] Skipping sensitive file: $BASENAME" >&2
    exit 0
    ;;
esac

# Find or init git repo
DIR="$(dirname "$FILE_PATH")"
if ! GIT_ROOT="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)"; then
  # Walk up to the first "project" directory (one level under the allowed prefix)
  PROJECT_DIR="$DIR"
  for prefix in "${ALLOWED_PREFIXES[@]}"; do
    if [[ "$DIR" == "$prefix"/* ]]; then
      # Extract first path component after prefix
      REL="${DIR#$prefix/}"
      PROJECT_DIR="$prefix/${REL%%/*}"
      break
    fi
  done

  echo "[$(date)] No git repo found. Initializing in $PROJECT_DIR" >&2
  git -C "$PROJECT_DIR" init -b main >&2

  # Create private GitHub repo
  REPO_NAME="$(basename "$PROJECT_DIR")"
  if command -v gh &>/dev/null; then
    echo "[$(date)] Creating private GitHub repo: $REPO_NAME" >&2
    gh repo create "$REPO_NAME" --private --source="$PROJECT_DIR" --push >&2 2>&1 || {
      # Repo may already exist, just add remote
      git -C "$PROJECT_DIR" remote add origin "$(gh repo view "$REPO_NAME" --json sshUrl -q .sshUrl 2>/dev/null)" >&2 2>&1 || true
    }
  fi

  GIT_ROOT="$PROJECT_DIR"
fi

cd "$GIT_ROOT"

# Check if there are changes worth committing
if git diff --quiet HEAD -- "$FILE_PATH" 2>/dev/null && ! git ls-files --others --exclude-standard -- "$FILE_PATH" | grep -q .; then
  echo "[$(date)] No changes to $FILE_PATH, skipping" >&2
  exit 0
fi

# Stage the changed file
git add "$FILE_PATH" >&2

# Build a short commit message
REL_PATH="${FILE_PATH#$GIT_ROOT/}"
git commit -m "auto: update $REL_PATH" --no-verify >&2 2>&1 || {
  echo "[$(date)] Nothing to commit" >&2
  exit 0
}

# Push (quietly, in background so we don't slow down Claude)
if git remote get-url origin &>/dev/null; then
  BRANCH="$(git branch --show-current)"
  git push -u origin "$BRANCH" --no-verify >&2 2>&1 &
  echo "[$(date)] Pushed $REL_PATH to origin/$BRANCH" >&2
else
  echo "[$(date)] No remote configured, commit only" >&2
fi

exit 0
