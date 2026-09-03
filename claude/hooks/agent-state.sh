#!/bin/sh
# Records what the agent in this pane is doing, for the session picker, the
# tmux status line, and `cc-state wait`. All the work is in cc-state; this is
# only here because settings.json needs a path under ~/.claude.
#
# ~/.claude/hooks is a symlink into the dotfiles repo, so resolve it before
# reaching sideways for zsh/common.
dir=$(cd "$(dirname "$0")" && pwd -P)
exec "$dir/../../zsh/common/cc-state" hook "$1"
