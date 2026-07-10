#!/usr/bin/env bash
# Prints the branch name for the given path, or nothing outside a git repo.
# Takes the path as an argument so tmux re-runs it the moment the path changes.

path="$1"
[ -d "$path" ] || exit 0

git -C "$path" symbolic-ref --quiet --short HEAD 2>/dev/null \
  || git -C "$path" rev-parse --short HEAD 2>/dev/null

exit 0
