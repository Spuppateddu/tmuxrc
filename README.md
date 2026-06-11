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
