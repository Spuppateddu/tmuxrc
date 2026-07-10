#!/usr/bin/env bash
# Prints the given path with $HOME collapsed to '~'.
# Takes the path as an argument so tmux re-runs it the moment the path changes.

path="$1"
[ -n "$path" ] || exit 0

if [ "$path" = "$HOME" ]; then
  printf '~'
else
  printf '%s' "~${path#"$HOME"}"
fi
