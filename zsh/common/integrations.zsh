# ──────────────────────────────────────────────
# Shell Integrations (cross-platform)
# ──────────────────────────────────────────────
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
if command -v ngrok &>/dev/null; then eval "$(ngrok completion)"; fi
