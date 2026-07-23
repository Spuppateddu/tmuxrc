#!/usr/bin/env bash
# Prints the whole status-line segment for the branch of the given path, or
# nothing at all outside a git repo — so the coloured block disappears instead
# of showing up empty.
# Takes the path as an argument so tmux re-runs it the moment the path changes;
# the segment's style (dracula's "#[fg=…]#[bg=…]") comes in as a second one.

path="$1"
style="${2-}"
[ -d "$path" ] || exit 0

branch="$(git -C "$path" symbolic-ref --quiet --short HEAD 2>/dev/null \
  || git -C "$path" rev-parse --short HEAD 2>/dev/null)"
[ -n "$branch" ] || exit 0

printf '%s %s ' "$style" "$branch"
