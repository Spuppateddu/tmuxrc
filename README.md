# .tmuxrc

My personal [tmux](https://github.com/tmux/tmux) configuration — vim-style
navigation, mouse support, clipboard integration, and the
[Dracula](https://github.com/dracula/tmux) theme with a Gruvbox color palette.

## Requirements

- `tmux` (3.0+ recommended)
- [TPM](https://github.com/tmux-plugins/tpm) — the tmux plugin manager
- `xclip` — for copying to the system clipboard

## Install

1. Clone this repo into `~/.tmuxrc`:

   ```sh
   git clone <repo-url> ~/.tmuxrc
   ```

2. Point your `~/.tmux.conf` at this config (create the file if it doesn't exist):

   ```sh
   echo 'source-file ~/.tmuxrc/config' > ~/.tmux.conf
   ```

3. Install TPM:

   ```sh
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

4. Start tmux and install the plugins by pressing the prefix followed by
   <kbd>I</kbd> (capital i):

   ```
   ` + I
   ```

## AI-agent status dots

Windows running an AI agent get a colored dot on the tab:

| Dot | Color | Meaning |
| --- | --- | --- |
| 🔵 | bright blue `#83A598` | working |
| 🟠 | bright orange `#FE8019` | waiting for your input (permission / prompt) |
| 🟢 | bright green `#B8BB26` | finished its turn |

The dot is drawn by tmux (`#[fg=...]`), not a colored emoji, so it shows up in
urxvt — which renders emoji monochrome.

"Waiting" is orange, not yellow: gruvbox yellow and green are both dark
yellow-greens and sit only ~18 ΔE00 apart, which reads as the same dot at one
character. Orange vs green is ~36.

Two halves make it work, and `./install.sh` sets up both:

- **Painting** — `scripts/name_windows.sh` reads the `@agent_state` pane option
  and prepends the dot.
- **Reporting** — the agent calls `scripts/agent_state.sh <busy|wait|done|clear>`,
  which sets `@agent_state` on its own pane (via the inherited `$TMUX_PANE`).
  This half lives in each agent's own config, outside this repo:

  | Agent | Wired into | Source of truth |
  | --- | --- | --- |
  | Claude Code | `~/.claude/settings.json` hooks | `agents/claude-hooks.json` |
  | opencode | `~/.config/opencode/plugin{,s}/tmux-status.js` | `agents/opencode-tmux-status.js` |

  Claude Code's `Notification` hook goes through `scripts/agent_notify.sh`
  rather than straight to `agent_state.sh`: that one event fires both for
  "needs your permission" *and* for the idle nudge ~60s **after** a turn ends,
  and treating the second as "waiting" would quietly repaint a finished green
  window orange. opencode needs no such split — it has a real
  `permission.asked` event.

`install.sh` only wires an agent it finds installed, merges into existing config
rather than overwriting it (your own hooks survive), and is safe to re-run.
**Don't edit the installed copies** — edit the files under `agents/` and re-run
`./install.sh`.

## Key bindings

The **prefix** key is the backtick <kbd>`</kbd> (press it twice to type a literal backtick).

| Binding | Action |
| --- | --- |
| `` ` `` | Prefix |
| `` ` `` `` ` `` | Jump to last window |
| `prefix` + `u` | Clear screen and scrollback history |
| `prefix` + `h/j/k/l` | Move between panes (vim-style) |
| `Ctrl+Shift+Arrows` | Resize the current pane |
| `prefix` + `"` | Split horizontally (same directory) |
| `prefix` + `%` | Split vertically (same directory) |
| `prefix` + `c` | New window (same directory) |
| `prefix` + `z` | Kill the current pane |
| `prefix` + `x` | Kill the current window (no confirm prompt) |
| `y` (copy-mode) | Copy selection to system clipboard |

## Plugins

- [tpm](https://github.com/tmux-plugins/tpm) — plugin manager
- [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) — sane defaults
- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) — seamless vim ↔ tmux pane navigation
- [dracula/tmux](https://github.com/dracula/tmux) — status bar theme (CPU, RAM, time, SSH session)
