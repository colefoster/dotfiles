# ──────────────────────────────────────────────
# ~/.zshrc — Dotfiles entrypoint
# ──────────────────────────────────────────────

DOTFILES_DIR="$HOME/dotfiles"

# PATH (must be before platform.zsh so mise and other tools are found)
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Detect platform
case "$(uname -s)" in
  Darwin) DOTFILES_PLATFORM="macos" ;;
  Linux)  DOTFILES_PLATFORM="linux" ;;
  *)      DOTFILES_PLATFORM="unknown" ;;
esac

# Load platform-specific config first (sets up compinit, env vars, etc.)
[[ -f "$DOTFILES_DIR/zsh/$DOTFILES_PLATFORM/platform.zsh" ]] && source "$DOTFILES_DIR/zsh/$DOTFILES_PLATFORM/platform.zsh"

# Load common config
for file in "$DOTFILES_DIR"/zsh/common/*.zsh; do
  [[ -f "$file" ]] && source "$file"
done

# Load machine-specific local config (gitignored)
[[ -f "$DOTFILES_DIR/zsh/$DOTFILES_PLATFORM/local.zsh" ]] && source "$DOTFILES_DIR/zsh/$DOTFILES_PLATFORM/local.zsh"
