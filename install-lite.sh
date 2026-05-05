#!/usr/bin/env bash
# Lightweight install: source shared aliases/functions/shelp/integrations
# into the existing ~/.zshrc without replacing it. Safe for work machines.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSHRC="$HOME/.zshrc"
MARKER_BEGIN="# >>> dotfiles-lite >>>"
MARKER_END="# <<< dotfiles-lite <<<"

touch "$ZSHRC"

# Remove any existing block so this is idempotent
if grep -qF "$MARKER_BEGIN" "$ZSHRC"; then
  echo "Removing previous dotfiles-lite block from $ZSHRC"
  sed -i.bak "/$MARKER_BEGIN/,/$MARKER_END/d" "$ZSHRC"
fi

cat >> "$ZSHRC" <<EOF

$MARKER_BEGIN
# Sourced from $DOTFILES_DIR — edit install-lite.sh in the repo to change.
for _f in \\
  "$DOTFILES_DIR/zsh/common/aliases.zsh" \\
  "$DOTFILES_DIR/zsh/common/functions.zsh" \\
  "$DOTFILES_DIR/zsh/common/shelp.zsh" \\
  "$DOTFILES_DIR/zsh/common/integrations.zsh"; do
  [[ -f "\$_f" ]] && source "\$_f"
done
unset _f
$MARKER_END
EOF

echo "Done. Run: source ~/.zshrc"
echo ""
echo "Optional tools (install what you want):"
echo "  brew install starship zoxide eza bat fd ripgrep fzf"
