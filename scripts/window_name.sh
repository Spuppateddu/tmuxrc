#!/usr/bin/env bash
# Pick a tmux window name from what's running in the window's active pane.
#
# Args:
#   $1 = pane_tty             (e.g. /dev/pts/3)
#   $2 = pane_current_command (the foreground command tmux sees, e.g. vim, node)
#
# Rule:
#   - An interpreter (node/python/…) -> dig the real tool name out of the
#     command line, because tools like claude/codex run *under* node/python and
#     would otherwise all show up as "node".
#   - Anything else -> the command as-is (vim, lazygit, zsh, …), which is what
#     tmux's own default naming shows.
#
# Not a per-tool allow-list: the interpreter case uses a generic "skip the
# boilerplate, keep the meaningful word" rule, so a new node/python CLI is named
# correctly without touching this file.

set -u

tty="${1:-}"
cmd="${2:-}"

case "$cmd" in
  node | nodejs | deno | bun | python | python2 | python3 | ruby | perl | php)
    dev="${tty#/dev/}"
    # Full argv of the foreground process on this tty (the one with '+' in STAT).
    args="$(ps -t "$dev" -o stat=,args= 2>/dev/null | awk '$1 ~ /\+/ { $1=""; sub(/^ /,""); print }' | tail -1)"

    # The script path is the first argument that is neither a flag nor the
    # interpreter itself. Everything after it belongs to the tool, not to us.
    script=""
    for tok in $args; do
      case "$tok" in
        -*) continue ;;                                # flags
        "$cmd" | */"$cmd" | */"$cmd".*) continue ;;    # the interpreter itself
        *) script="$tok"; break ;;
      esac
    done

    # Walk the script path from the end and take the first component that means
    # something, skipping generic entrypoint/dir names and npm scopes. So
    # …/@anthropic-ai/claude-code/cli.js -> claude-code, …/codex/dist/cli.js ->
    # codex, …/bin/vite -> vite, …/server/index.js -> server.
    name=""
    rest="$script"
    while [ -n "$rest" ]; do
      comp="${rest##*/}"          # last path component
      rest="${rest%/*}"           # drop it
      [ "$rest" = "$comp" ] && rest=""   # no more slashes
      comp="${comp%.*}"           # strip one extension
      case "$comp" in
        '' | .* | @* | cli | index | main | __main__ | bin | dist | src | lib | build | out | node_modules) continue ;;
        *) name="$comp"; break ;;
      esac
    done

    printf '%s\n' "${name:-$cmd}"
    exit 0
    ;;
esac

printf '%s\n' "$cmd"
