// Report opencode's state to tmux, so name_windows.sh can paint a status
// marker on the window tab. The mirror image of the Claude Code hooks that
// install.sh writes into ~/.claude/settings.json.
//
// Installed by ~/.tmuxrc/install.sh, which substitutes the absolute path to
// agent_state.sh below. Editing this copy does nothing — edit the repo one and
// re-run ./install.sh.

const AGENT_STATE = "__AGENT_STATE_SH__"

export const TmuxStatus = async ({ $ }) => {
  // A status marker is never worth breaking the agent over: swallow every
  // failure (not in tmux, script missing, pane already gone).
  const mark = (state) => $`${AGENT_STATE} ${state}`.quiet().nothrow()

  return {
    "session.created": async () => { await mark("busy") },
    // Re-assert busy after each tool: that's what clears the [ ] marker once
    // you've answered a permission prompt.
    "tool.execute.after": async () => { await mark("busy") },
    "permission.asked": async () => { await mark("wait") },
    "permission.replied": async () => { await mark("busy") },
    "session.idle": async () => { await mark("done") },
    "session.error": async () => { await mark("wait") },
  }
}
