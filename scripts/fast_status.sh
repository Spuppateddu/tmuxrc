#!/usr/bin/env bash
# Swaps dracula's cwd/git commands for path-aware ones. Passing the path as an
# argument changes the command string, which bypasses tmux's 1s per-job cache.

set -u
scripts="$HOME/.tmuxrc/scripts"
dracula="$HOME/.tmux/plugins/tmux/scripts"

right="$(tmux show-option -gqv status-right)"
[ -n "$right" ] || exit 0

right="${right//"#($dracula/cwd.sh)"/"#($scripts/cwd.sh \"#{pane_current_path}\")"}"
right="${right//"#($dracula/git.sh)"/"#($scripts/git_branch.sh \"#{pane_current_path}\")"}"

tmux set-option -g status-right "$right"
