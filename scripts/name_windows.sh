#!/usr/bin/env bash
# Name every window after what's running in its active pane. Invoked once per
# status-interval from a hidden #() in the status line, so it re-checks ~1s.
#
# tmux's own automatic-rename can't see through interpreters (codex and friends
# run under node/python and show up as "node"), so we drive naming ourselves via
# window_name.sh and keep automatic-rename off.

set -u
NAME="$HOME/.tmuxrc/scripts/window_name.sh"

tmux list-panes -a -f '#{pane_active}' \
  -F '#{window_id}|#{pane_current_command}|#{pane_tty}|#{window_name}' |
while IFS='|' read -r wid cmd tty name; do
  desired="$("$NAME" "$tty" "$cmd")"
  [ -n "$desired" ] || continue
  [ "$name" = "$desired" ] || tmux rename-window -t "$wid" "$desired"
done
