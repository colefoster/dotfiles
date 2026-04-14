# ──────────────────────────────────────────────
# Shell Integrations (cross-platform)
# ──────────────────────────────────────────────
if command -v fzf &>/dev/null; then eval "$(fzf --zsh)"; fi
if command -v ngrok &>/dev/null; then eval "$(ngrok completion)"; fi
