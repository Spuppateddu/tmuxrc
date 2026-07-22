#!/usr/bin/env bash
# Append the window-namer to status-right so tmux runs it about once a second,
# as a hidden side-effect of drawing the status line (name_windows.sh prints
# nothing). Kept in a script because run-shell format-expands its argument —
# which would execute the #() at parse time instead of storing it. Runs after
# fast_status.sh so the append survives that rewrite. Idempotent.

set -u

right="$(tmux show-option -gqv status-right)"
case "$right" in
  *name_windows.sh*) exit 0 ;;   # already attached
esac

tmux set-option -ga status-right '#(~/.tmuxrc/scripts/name_windows.sh)'
