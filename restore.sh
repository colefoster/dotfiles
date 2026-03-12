#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$DOTFILES_DIR/zsh-backup"

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "No backup found at $BACKUP_DIR"
  exit 1
fi

echo "Restoring original zsh config from backup..."

# Remove symlinks the install script created
[[ -L "$HOME/.zshrc" ]] && rm "$HOME/.zshrc"
[[ -L "$HOME/.config/starship.toml" ]] && rm "$HOME/.config/starship.toml"

# Restore originals
cp "$BACKUP_DIR/zshrc" "$HOME/.zshrc"
cp "$BACKUP_DIR/zprofile" "$HOME/.zprofile"
cp "$BACKUP_DIR/starship.toml" "$HOME/.config/starship.toml"
mkdir -p "$HOME/.zsh"
cp "$BACKUP_DIR"/zsh/* "$HOME/.zsh/"

echo "Done! Original config restored. Run: source ~/.zshrc"
