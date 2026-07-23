#!/usr/bin/env bash
# Name every window after what's running in its active pane. Invoked once per
# status-interval from a hidden #() in the status line, so it re-checks ~1s.
#
# tmux's own automatic-rename can't see through interpreters (codex and friends
# run under node/python and show up as "node"), so we drive naming ourselves via
# window_name.sh and keep automatic-rename off.

set -u
NAME="$HOME/.tmuxrc/scripts/window_name.sh"

# Status dot for AI-agent windows. @agent_state is a per-pane option set by
# agent_state.sh (from Claude Code's hooks and opencode's plugin: busy/wait/
# done). We only decorate windows whose program resolves to a known agent, so a
# stale marker left on a pane that has since moved on can't leak a dot.
#
# The dot is colored by *tmux* via #[fg=...] rather than by a colored emoji:
# urxvt renders emoji monochrome, so 🔵/🟡/🟢 all look the same grey. tmux
# applies the #[fg] when it draws the status bar, so the color shows in any
# terminal. After the dot we restore the normal tab foreground (TABFG) instead
# of #[default] so we don't clobber the focused window's red background.
#
# Colors are the *bright* gruvbox variants, and "waiting" is orange rather than
# yellow: gruvbox yellow and green are both dark yellow-greens (CIEDE2000 ~18
# apart — confusable at one character), while orange vs green is ~36. Bright red
# would separate further still, but it washes out against the focused window's
# red background.
TABFG='#EBDBB2'                          # dracula white = normal window-tab fg
BUSY="#[fg=#83A598]●#[fg=$TABFG] "       # working            (bright blue)
WAIT="#[fg=#FE8019]●#[fg=$TABFG] "       # waiting for input  (bright orange)
DONE="#[fg=#B8BB26]●#[fg=$TABFG] "       # finished / ready   (bright green)

tmux list-panes -a -f '#{pane_active}' \
  -F '#{window_id}|#{pane_current_command}|#{pane_tty}|#{window_name}|#{@agent_state}' |
while IFS='|' read -r wid cmd tty name state; do
  desired="$("$NAME" "$tty" "$cmd")"
  [ -n "$desired" ] || continue

  case "$desired" in
    claude | claude-* | opencode )
      case "$state" in
        busy) desired="$BUSY$desired" ;;
        wait) desired="$WAIT$desired" ;;
        done) desired="$DONE$desired" ;;
      esac
      ;;
  esac

  [ "$name" = "$desired" ] || tmux rename-window -t "$wid" "$desired"
done
