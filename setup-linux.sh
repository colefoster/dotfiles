#!/usr/bin/env bash
# ──────────────────────────────────────────────
# Fresh Ubuntu setup for dotfiles toolchain
# Run: chmod +x setup-linux.sh && ./setup-linux.sh
# ──────────────────────────────────────────────
set -euo pipefail

echo "==> Updating apt..."
sudo apt update

# ──────────────────────────────────────────────
# System packages
# ──────────────────────────────────────────────
echo "==> Installing system packages..."
sudo apt install -y \
  git curl wget unzip p7zip-full \
  python3 python3-pip python3-venv \
  jq lsof xclip build-essential \
  zsh btop duf direnv neovim

# ──────────────────────────────────────────────
# bat (Ubuntu names it batcat)
# ──────────────────────────────────────────────
echo "==> Installing bat..."
sudo apt install -y bat
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat

# ──────────────────────────────────────────────
# ripgrep
# ──────────────────────────────────────────────
echo "==> Installing ripgrep..."
sudo apt install -y ripgrep

# ──────────────────────────────────────────────
# fd (Ubuntu names it fdfind)
# ──────────────────────────────────────────────
echo "==> Installing fd..."
sudo apt install -y fd-find
ln -sf /usr/bin/fdfind ~/.local/bin/fd

# ──────────────────────────────────────────────
# eza (ls replacement)
# ──────────────────────────────────────────────
echo "==> Installing eza..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo apt update && sudo apt install -y eza

# ──────────────────────────────────────────────
# fzf
# ──────────────────────────────────────────────
echo "==> Installing fzf..."
if [[ ! -d ~/.fzf ]]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
fi
~/.fzf/install --all --no-bash --no-fish

# ──────────────────────────────────────────────
# zoxide
# ──────────────────────────────────────────────
echo "==> Installing zoxide..."
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# ──────────────────────────────────────────────
# starship (prompt)
# ──────────────────────────────────────────────
echo "==> Installing starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# ──────────────────────────────────────────────
# mise (version manager — replaces nvm/pyenv/etc)
# ──────────────────────────────────────────────
echo "==> Installing mise..."
curl https://mise.run | sh

# ──────────────────────────────────────────────
# glow (markdown renderer)
# ──────────────────────────────────────────────
echo "==> Installing glow..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install -y glow

# ──────────────────────────────────────────────
# delta (git diff pager)
# ──────────────────────────────────────────────
echo "==> Installing delta..."
DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -o /tmp/delta.deb
sudo dpkg -i /tmp/delta.deb

# ──────────────────────────────────────────────
# hyperfine (benchmarking)
# ──────────────────────────────────────────────
echo "==> Installing hyperfine..."
HYPERFINE_VERSION=$(curl -s "https://api.github.com/repos/sharkdp/hyperfine/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/sharkdp/hyperfine/releases/download/${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION#v}_amd64.deb" -o /tmp/hyperfine.deb
sudo dpkg -i /tmp/hyperfine.deb

# ──────────────────────────────────────────────
# lazygit
# ──────────────────────────────────────────────
echo "==> Installing lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r '.tag_name' | tr -d 'v')
curl -sSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" | tar xz -C /tmp lazygit
sudo mv /tmp/lazygit /usr/local/bin/

# ──────────────────────────────────────────────
# lazydocker
# ──────────────────────────────────────────────
echo "==> Installing lazydocker..."
curl -sSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# ──────────────────────────────────────────────
# ctop (container top)
# ──────────────────────────────────────────────
echo "==> Installing ctop..."
CTOP_VERSION=$(curl -s "https://api.github.com/repos/bcicen/ctop/releases/latest" | jq -r '.tag_name')
sudo curl -sSL -o /usr/local/bin/ctop "https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION#v}-linux-amd64"
sudo chmod +x /usr/local/bin/ctop

# ──────────────────────────────────────────────
# dive (docker image inspector)
# ──────────────────────────────────────────────
echo "==> Installing dive..."
DIVE_VERSION=$(curl -s "https://api.github.com/repos/wagoodman/dive/releases/latest" | jq -r '.tag_name' | tr -d 'v')
curl -sSL "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb" -o /tmp/dive.deb
sudo dpkg -i /tmp/dive.deb

# ──────────────────────────────────────────────
# dust (du replacement)
# ──────────────────────────────────────────────
echo "==> Installing dust..."
DUST_VERSION=$(curl -s "https://api.github.com/repos/bootandy/dust/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/bootandy/dust/releases/download/${DUST_VERSION}/dust-${DUST_VERSION}-x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
sudo mv /tmp/dust-${DUST_VERSION}-x86_64-unknown-linux-gnu/dust /usr/local/bin/

# ──────────────────────────────────────────────
# procs (ps replacement)
# ──────────────────────────────────────────────
echo "==> Installing procs..."
PROCS_VERSION=$(curl -s "https://api.github.com/repos/dalance/procs/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/dalance/procs/releases/download/${PROCS_VERSION}/procs-${PROCS_VERSION}-x86_64-linux.zip" -o /tmp/procs.zip
unzip -o /tmp/procs.zip -d /tmp/procs-bin
sudo mv /tmp/procs-bin/procs /usr/local/bin/

# ──────────────────────────────────────────────
# curlie (curl with httpie-style output)
# ──────────────────────────────────────────────
echo "==> Installing curlie..."
CURLIE_VERSION=$(curl -s "https://api.github.com/repos/rs/curlie/releases/latest" | jq -r '.tag_name' | tr -d 'v')
curl -sSL "https://github.com/rs/curlie/releases/download/v${CURLIE_VERSION}/curlie_${CURLIE_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp curlie
sudo mv /tmp/curlie /usr/local/bin/

# ──────────────────────────────────────────────
# doggo (dig replacement)
# ──────────────────────────────────────────────
echo "==> Installing doggo..."
DOGGO_VERSION=$(curl -s "https://api.github.com/repos/mr-karan/doggo/releases/latest" | jq -r '.tag_name' | tr -d 'v')
curl -sSL "https://github.com/mr-karan/doggo/releases/download/v${DOGGO_VERSION}/doggo_${DOGGO_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/doggo /usr/local/bin/

# ──────────────────────────────────────────────
# sd (sed replacement)
# ──────────────────────────────────────────────
echo "==> Installing sd..."
SD_VERSION=$(curl -s "https://api.github.com/repos/chmln/sd/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/chmln/sd/releases/download/${SD_VERSION}/sd-${SD_VERSION}-x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
sudo mv /tmp/sd-${SD_VERSION}-x86_64-unknown-linux-gnu/sd /usr/local/bin/

# ──────────────────────────────────────────────
# difftastic (diff replacement)
# ──────────────────────────────────────────────
echo "==> Installing difftastic..."
DFT_VERSION=$(curl -s "https://api.github.com/repos/Wilfred/difftastic/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/Wilfred/difftastic/releases/download/${DFT_VERSION}/difft-x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
sudo mv /tmp/difft /usr/local/bin/

# ──────────────────────────────────────────────
# tokei (lines of code counter)
# ──────────────────────────────────────────────
echo "==> Installing tokei..."
TOKEI_VERSION=$(curl -s "https://api.github.com/repos/XAMPPRocky/tokei/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/XAMPPRocky/tokei/releases/download/${TOKEI_VERSION}/tokei-x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
sudo mv /tmp/tokei /usr/local/bin/

# ──────────────────────────────────────────────
# watchexec (file watcher)
# ──────────────────────────────────────────────
echo "==> Installing watchexec..."
WATCHEXEC_VERSION=$(curl -s "https://api.github.com/repos/watchexec/watchexec/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/watchexec/watchexec/releases/download/${WATCHEXEC_VERSION}/watchexec-${WATCHEXEC_VERSION}-x86_64-unknown-linux-gnu.tar.xz" | tar xJ -C /tmp
sudo mv /tmp/watchexec-${WATCHEXEC_VERSION}-x86_64-unknown-linux-gnu/watchexec /usr/local/bin/

# ──────────────────────────────────────────────
# bandwhich (network usage)
# ──────────────────────────────────────────────
echo "==> Installing bandwhich..."
BANDWHICH_VERSION=$(curl -s "https://api.github.com/repos/imsnif/bandwhich/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/imsnif/bandwhich/releases/download/${BANDWHICH_VERSION}/bandwhich-${BANDWHICH_VERSION}-x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
sudo mv /tmp/bandwhich /usr/local/bin/

# ──────────────────────────────────────────────
# mkcert (local HTTPS certs)
# ──────────────────────────────────────────────
echo "==> Installing mkcert..."
MKCERT_VERSION=$(curl -s "https://api.github.com/repos/FiloSottile/mkcert/releases/latest" | jq -r '.tag_name')
curl -sSL "https://github.com/FiloSottile/mkcert/releases/download/${MKCERT_VERSION}/mkcert-${MKCERT_VERSION}-linux-amd64" -o /tmp/mkcert
sudo mv /tmp/mkcert /usr/local/bin/ && sudo chmod +x /usr/local/bin/mkcert

# ──────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────
echo ""
echo "==> All tools installed!"
echo ""
echo "Next steps:"
echo "  1. chsh -s \$(which zsh)     # set zsh as default shell"
echo "  2. ./install.sh              # symlink dotfiles"
echo "  3. cp zsh/linux/local.zsh.example zsh/linux/local.zsh"
echo "  4. Open a new shell session"
