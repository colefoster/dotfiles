# ──────────────────────────────────────────────
# macOS-specific configuration
# ──────────────────────────────────────────────

# Platform commands used by common functions
export DOTFILES_OPEN_CMD="open"
export DOTFILES_COPY_CMD="pbcopy"
export DOTFILES_PASTE_CMD="pbpaste"

# Homebrew completions (must be before compinit)
FPATH="/opt/homebrew/share/zsh/site-functions:${FPATH}"
autoload -Uz compinit && compinit

# fzf via Homebrew
set rtp+=/opt/homebrew/opt/fzf

# ──────────────────────────────────────────────
# macOS Aliases
# ──────────────────────────────────────────────
alias ip='command curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias cleanup='command find . -name ".DS_Store" -delete'
alias top='btop'
alias bw='sudo bandwhich'

# Quick navigation
alias work='cd ~/Code'
alias dev='cd ~/Dev'
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'

# ──────────────────────────────────────────────
# macOS Functions
# ──────────────────────────────────────────────

# Copy SSH pubkey to clipboard
copyssh() { pbcopy < ~/.ssh/id_ed25519.pub && echo "SSH key copied to clipboard"; }

# JSON pretty print from clipboard
jsonp() { pbpaste | python3 -m json.tool | command bat -l json; }

# Decode JWT from clipboard
jwt() { pbpaste | cut -d. -f2 | base64 -d 2>/dev/null | python3 -m json.tool | command bat -l json; }

# ──────────────────────────────────────────────
# Homebrew
# ──────────────────────────────────────────────
alias brewup='brew update && brew upgrade && brew cleanup'
alias brewls='brew list'
alias brewsr='brew search'
alias brewinfo='brew info'

# ──────────────────────────────────────────────
# macOS Tool Managers
# ──────────────────────────────────────────────
eval "$(mise activate zsh)"
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
