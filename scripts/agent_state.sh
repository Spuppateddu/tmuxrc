#!/usr/bin/env bash
# Record an AI agent's state on the tmux pane it runs in, so the window namer
# (name_windows.sh) can prepend a status dot to the window name. Shared by both
# Claude Code (via ~/.claude/settings.json hooks) and opencode (via its plugin
# at ~/.config/opencode/plugin/tmux-status.js).
#
# The agent inherits $TMUX_PANE from the pane it was launched in, so we can
# target that exact pane even though this is a separate short-lived process.
#
# Usage: agent_state.sh <busy|wait|done|clear>
#   busy  - agent is working
#   wait  - agent needs your input (permission / prompt)
#   done  - agent finished its turn
#   clear - drop the marker (session ended)

set -u

state="${1:-}"
pane="${TMUX_PANE:-}"

# Nothing to do if we're not inside tmux (e.g. run in a plain terminal).
[ -n "$pane" ] || exit 0

if [ "$state" = "clear" ]; then
  tmux set-option -pu -t "$pane" @agent_state 2>/dev/null
else
  tmux set-option -p -t "$pane" @agent_state "$state" 2>/dev/null
fi

# Nudge the status line so the dot updates now instead of at the next tick.
tmux refresh-client -S 2>/dev/null

exit 0
