#!/usr/bin/env bash
# Swaps dracula's cwd/git commands for path-aware ones. Passing the path as an
# argument changes the command string, which bypasses tmux's 1s per-job cache.
#
# The git segment gets a further twist: dracula wraps every plugin in its own
# "#[fg=…]#[bg=…] … " block, so a repo-less directory still paints an empty
# coloured rectangle. We lift that style out of status-right and hand it to
# git_branch.sh, which prints style + branch together, or nothing at all.

set -u
scripts="$HOME/.tmuxrc/scripts"
dracula="$HOME/.tmux/plugins/tmux/scripts"

right="$(tmux show-option -gqv status-right)"
[ -n "$right" ] || exit 0

right="${right//"#($dracula/cwd.sh)"/"#($scripts/cwd.sh \"#{pane_current_path}\")"}"

# Match either dracula's own git call or an already-swapped one, so re-running
# this script on a live session stays a no-op rather than doubling up.
for call in "#($dracula/git.sh)" "#($scripts/git_branch.sh \"#{pane_current_path}\")"; do
  [[ "$right" == *"$call"* ]] || continue

  before="${right%%"$call"*}"
  after="${right#*"$call"}"

  # Peel the segment's padding and its run of #[…] style directives off the end
  # of `before`; the next segment sets its own colours, so nothing is lost.
  style=""
  [ "${before: -1}" = " " ] && before="${before%?}"
  while [[ "$before" =~ (\#\[[^]]*\])$ ]]; do
    style="${BASH_REMATCH[1]}$style"
    before="${before%"${BASH_REMATCH[1]}"}"
  done
  [ "${after:0:1}" = " " ] && after="${after#?}"

  right="$before#($scripts/git_branch.sh \"#{pane_current_path}\" \"$style\")$after"
  break
done

tmux set-option -g status-right "$right"
