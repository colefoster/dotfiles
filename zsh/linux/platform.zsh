# ──────────────────────────────────────────────
# Linux-specific configuration
# ──────────────────────────────────────────────

# Platform commands used by common functions
export DOTFILES_OPEN_CMD="xdg-open"
export DOTFILES_COPY_CMD="xclip -selection clipboard"
export DOTFILES_PASTE_CMD="xclip -selection clipboard -o"

# Completions
autoload -Uz compinit && compinit

# ──────────────────────────────────────────────
# Linux Aliases
# ──────────────────────────────────────────────
alias ip='command curl -s ifconfig.me'
alias localip='hostname -I | awk "{print \$1}"'
copyssh() { xclip -selection clipboard < ~/.ssh/id_ed25519.pub && echo "SSH key copied to clipboard"; }
alias flushdns='sudo systemd-resolve --flush-caches 2>/dev/null || sudo resolvectl flush-caches 2>/dev/null || echo "No systemd-resolved running"'
alias cleanup='command find . -name ".DS_Store" -delete'
alias top='btop'
alias bw='sudo bandwhich'

# Quick navigation
alias dev='cd ~/dev'
alias dl='cd ~/Downloads'

# ──────────────────────────────────────────────
# Linux Functions
# ──────────────────────────────────────────────

# JSON pretty print from clipboard
jsonp() { xclip -selection clipboard -o | python3 -m json.tool | command bat -l json; }

# Decode JWT from clipboard
jwt() { xclip -selection clipboard -o | cut -d. -f2 | base64 -d 2>/dev/null | python3 -m json.tool | command bat -l json; }

# ──────────────────────────────────────────────
# Package Manager (apt-based, adjust if needed)
# ──────────────────────────────────────────────
alias aptup='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
alias aptls='dpkg --list'
alias aptsr='apt search'
alias aptinfo='apt show'
alias aptin='sudo apt install -y'

# ──────────────────────────────────────────────
# Systemd
# ──────────────────────────────────────────────
alias sc='sudo systemctl'
alias scr='sudo systemctl restart'
alias scs='sudo systemctl status'
alias sce='sudo systemctl enable'
alias scd='sudo systemctl disable'
alias scl='sudo journalctl -u'
alias sclf='sudo journalctl -fu'

# ──────────────────────────────────────────────
# Linux Tool Managers
# ──────────────────────────────────────────────
if command -v mise &>/dev/null; then
  # Add shims to PATH so mise-managed tools are available immediately
  export PATH="$HOME/.local/share/mise/shims:$PATH"
  eval "$(mise activate zsh)"
fi
if command -v direnv &>/dev/null; then eval "$(direnv hook zsh)"; fi
if command -v starship &>/dev/null; then eval "$(starship init zsh)"; fi
