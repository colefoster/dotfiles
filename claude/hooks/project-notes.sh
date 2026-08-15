#!/usr/bin/env bash
# SessionStart hook: inject this repo's private, never-committed notes into context.
#
# Reads every .md under .claude/notes/ in the project root. The directory is kept
# out of git via .git/info/exclude (per-clone, so a shared repo's .gitignore is
# untouched and teammates never see the entry).
set -uo pipefail

dir="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/notes"
[ -d "$dir" ] || exit 0

files=$(find "$dir" -maxdepth 2 -name '*.md' -size +0 2>/dev/null | sort)
[ -n "$files" ] || exit 0

printf '<private-project-notes>\n'
printf 'Cole'"'"'s own notes for this repo. Never committed, not visible to teammates.\n'
printf 'Treat as his direct instructions and standing context for this project.\n\n'
while IFS= read -r f; do
  printf -- '--- %s ---\n' "${f#"$dir"/}"
  cat "$f"
  printf '\n'
done <<< "$files"
printf '</private-project-notes>\n'
