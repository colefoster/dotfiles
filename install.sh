#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
  *)      echo "Unsupported platform"; exit 1 ;;
esac

echo "Installing dotfiles for $PLATFORM..."

# Backup existing files
backup() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "  Backing up $target → ${target}.bak"
    mv "$target" "${target}.bak"
  elif [[ -L "$target" ]]; then
    rm "$target"
  fi
}

# Create symlink
link() {
  local src="$1" dst="$2"
  backup "$dst"
  echo "  Linking $dst → $src"
  ln -sf "$src" "$dst"
}

# Core symlinks
link "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"

# Starship
mkdir -p "$HOME/.config"
link "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# Create local.zsh from example if it doesn't exist
if [[ ! -f "$DOTFILES_DIR/zsh/$PLATFORM/local.zsh" ]]; then
  if [[ -f "$DOTFILES_DIR/zsh/$PLATFORM/local.zsh.example" ]]; then
    cp "$DOTFILES_DIR/zsh/$PLATFORM/local.zsh.example" "$DOTFILES_DIR/zsh/$PLATFORM/local.zsh"
    echo "  Created zsh/$PLATFORM/local.zsh from example — edit with your machine-specific config"
  fi
fi

echo ""
echo "Done! Restart your shell or run: source ~/.zshrc"
