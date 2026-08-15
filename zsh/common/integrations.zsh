# ──────────────────────────────────────────────
# Shell Integrations (cross-platform)
# ──────────────────────────────────────────────
if command -v fzf &>/dev/null; then eval "$(fzf --zsh)"; fi
if command -v ngrok &>/dev/null; then eval "$(ngrok completion)"; fi

# Tab-complete files newest-first (by mtime instead of alphabetical)
zstyle ':completion:*' file-sort modification

# Alt-N: insert newest file in cwd at cursor
_insert_newest_file() {
  local f=$(command ls -t 2>/dev/null | head -1)
  [[ -n "$f" ]] && LBUFFER+="${(q)f} "
}
zle -N _insert_newest_file
bindkey '^[n' _insert_newest_file
