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

# tmux
link "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

# Starship
mkdir -p "$HOME/.config"
link "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# Ghostty. Only the macOS app-support file, where the Ghostty Config app writes
# the theme.
if [[ "$PLATFORM" == "macos" ]]; then
  mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
  link "$DOTFILES_DIR/ghostty/config.ghostty" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
fi

# Window manager: AeroSpace + SketchyBar + JankyBorders.
#   brew install --cask nikitabobko/tap/aerospace
#   brew install FelixKratz/formulae/sketchybar FelixKratz/formulae/borders
# Nothing starts at login. AeroSpace launches the bar and the borders itself,
# so opening AeroSpace turns the whole setup on and quitting it turns it off.
if [[ "$PLATFORM" == "macos" ]]; then
  mkdir -p "$HOME/.config/aerospace"
  link "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
  link "$DOTFILES_DIR/theme"      "$HOME/.config/theme"
  link "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
  link "$DOTFILES_DIR/borders"    "$HOME/.config/borders"

  # Karabiner rewrites karabiner.json in place whenever you touch its UI, which
  # would clobber a symlink's target. Copy it, and only when there is nothing
  # there yet — an existing profile is the user's, not ours.
  mkdir -p "$HOME/.config/karabiner"
  if [[ ! -e "$HOME/.config/karabiner/karabiner.json" ]]; then
    echo "  Copying karabiner.json (caps -> hyper)"
    cp "$DOTFILES_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
  else
    echo "  Skipping karabiner.json — one already exists; merge by hand if you want the caps rule"
  fi
fi

# Claude Code
mkdir -p "$HOME/.claude"
link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link "$DOTFILES_DIR/claude/settings.local.json" "$HOME/.claude/settings.local.json"
link "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
link "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
link "$DOTFILES_DIR/claude/scripts" "$HOME/.claude/scripts"
link "$DOTFILES_DIR/claude/skills" "$HOME/.claude/skills"
link "$DOTFILES_DIR/claude/hooks" "$HOME/.claude/hooks"

# Create local.zsh from example if it doesn't exist
if [[ ! -f "$DOTFILES_DIR/zsh/$PLATFORM/local.zsh" ]]; then
  if [[ -f "$DOTFILES_DIR/zsh/$PLATFORM/local.zsh.example" ]]; then
    cp "$DOTFILES_DIR/zsh/$PLATFORM/local.zsh.example" "$DOTFILES_DIR/zsh/$PLATFORM/local.zsh"
    echo "  Created zsh/$PLATFORM/local.zsh from example — edit with your machine-specific config"
  fi
fi

echo ""
echo "Done! Restart your shell or run: source ~/.zshrc"
