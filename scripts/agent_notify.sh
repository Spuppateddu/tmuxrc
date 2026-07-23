#!/usr/bin/env bash
# Claude Code's Notification hook fires for two situations that mean opposite
# things to a status dot:
#
#   "Claude needs your permission to use X"  - the turn is blocked on you   -> wait
#   "Claude is waiting for your input"       - the turn already ENDED; this
#       arrives about a minute after Stop, and mapping it to `wait` would
#       repaint a finished (green) window orange while you weren't looking.
#
# So read the notification and pick the right state, then hand off to
# agent_state.sh. opencode needs none of this: it has a real permission.asked
# event, so its plugin calls agent_state.sh directly.
#
# Matching is a plain substring test against the raw hook JSON rather than a jq
# field lookup: no dependency, and an unparseable payload still falls through to
# the safe answer.
#
# Usage: agent_notify.sh          (hook JSON on stdin)

set -u

input="$(cat 2>/dev/null || true)"

case "$input" in
  # Idle nudge: the turn is over, so keep showing "finished".
  *"waiting for your input"*) state=done ;;
  # Anything else (permission prompts, and any wording we don't know yet) is
  # treated as needing you - a false orange is cheap, a missed one is not.
  *) state=wait ;;
esac

exec "$(dirname "$0")/agent_state.sh" "$state"
