#!/usr/bin/env bash
# Usage: dir_git.sh <folder|branch> <path>
# Prints the basename of <path>, or its git branch (empty when not a repo).

mode="$1"
path="$2"
[ -d "$path" ] || exit 0

case "$mode" in
  folder)
    printf '%s' "$(basename "$path")"
    ;;
  branch)
    branch=$(git -C "$path" symbolic-ref --quiet --short HEAD 2>/dev/null \
      || git -C "$path" rev-parse --short HEAD 2>/dev/null)
    [ -n "$branch" ] && printf ' %s ' "$branch"
    ;;
esac

exit 0
