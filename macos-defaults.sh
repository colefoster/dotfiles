#!/usr/bin/env bash
# macOS settings that a symlink can't express. Run by hand, not by install.sh —
# these change the running system, and you should know when that happens.
#
#   bash ~/dotfiles/macos-defaults.sh
#
# Only settings this setup actually depends on live here. Resist the urge to
# paste in a 200-line "awesome macOS defaults" list; you will not remember why
# any of it is here in six months.
set -euo pipefail

echo "Hiding the native menu bar (SketchyBar replaces it)…"
defaults write NSGlobalDomain _HIHideMenuBar -bool true

echo "Disabling the Spaces auto-rearrange that fights a tiler…"
defaults write com.apple.dock mru-spaces -bool false

echo "Faster key repeat, so hjkl navigation doesn't lag behind your hands…"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

cat <<'NOTE'

Done. Two things no script can do — macOS requires a human click:
  • AeroSpace          → System Settings → Privacy & Security → Accessibility
  • Karabiner-Elements → Privacy & Security → Input Monitoring, plus its
                         driver system extension on first launch

To undo:
  defaults delete NSGlobalDomain _HIHideMenuBar
  defaults write com.apple.dock mru-spaces -bool true && killall Dock
NOTE
