#!/usr/bin/env bash
# ──────────────────────────────────────────────
# Fresh Ubuntu setup for dotfiles toolchain
# Uses apt for base packages, mise for everything else.
# Update all mise tools later with: mise upgrade
# ──────────────────────────────────────────────
set -euo pipefail

echo "==> Updating apt..."
sudo apt update

# ──────────────────────────────────────────────
# Base system packages (apt only — these are fine from Ubuntu repos)
# ──────────────────────────────────────────────
echo "==> Installing base system packages..."
sudo apt install -y \
  git curl wget unzip p7zip-full \
  python3 python3-pip python3-venv \
  jq lsof xclip build-essential \
  zsh

# ──────────────────────────────────────────────
# Install mise (manages everything else)
# ──────────────────────────────────────────────
echo "==> Installing mise..."
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# ──────────────────────────────────────────────
# Install all CLI tools via mise
# ──────────────────────────────────────────────
echo "==> Installing tools via mise..."
mise use -g \
  bat \
  ripgrep \
  fd \
  eza \
  fzf \
  zoxide \
  starship \
  neovim \
  delta \
  dust \
  duf \
  aqua:dalance/procs \
  sd \
  difftastic \
  curlie \
  doggo \
  glow \
  lazygit \
  lazydocker \
  hyperfine \
  aqua:XAMPPRocky/tokei \
  watchexec \
  aqua:imsnif/bandwhich \
  mkcert \
  btop \
  ctop \
  dive \
  direnv

# ──────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────
echo ""
echo "==> All tools installed!"
echo ""
echo "To update everything later:"
echo "  mise upgrade"
echo ""
echo "Next steps:"
echo "  1. chsh -s \$(which zsh)     # set zsh as default shell"
echo "  2. ./install.sh              # symlink dotfiles"
echo "  3. cp zsh/linux/local.zsh.example zsh/linux/local.zsh"
echo "  4. Open a new shell session"
