#!/usr/bin/env bash
# Install/update everything this tmux config needs, then wire the repo in:
# apt deps, point ~/.tmux.conf at ./config, TPM + plugins, live-reload a
# running server.
#
# Idempotent — safe to re-run any time. Orchestrators (e.g.
# best-linux-environment) clone/update this repo and just call ./install.sh;
# this script owns every tmux-specific step, the orchestrator knows nothing.
#
# Usage: ./install.sh [--dry-run]     (also honours DRY_RUN=true from the env)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
DRY_RUN="${DRY_RUN:-false}"

# ── Self-contained helpers (no external lib — this repo installs alone) ──────
if [[ -t 1 ]]; then
    C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
    C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_OFF=$'\033[0m'
else
    C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_DIM=''; C_BOLD=''; C_OFF=''
fi
step()  { printf '%s▸%s %s\n' "$C_BLUE"  "$C_OFF" "$*"; }
ok()    { printf '%s✓%s %s\n' "$C_GREEN" "$C_OFF" "$*"; }
skip()  { printf '%s·%s %s%s%s\n' "$C_DIM" "$C_OFF" "$C_DIM" "$*" "$C_OFF"; }
warn()  { printf '%s!%s %s\n' "$C_YELLOW" "$C_OFF" "$*"; }
title() { printf '\n%s══ %s ══%s\n' "$C_BOLD" "$*" "$C_OFF"; }
run() {
    if [[ "$DRY_RUN" == true ]]; then
        printf '%s  would run:%s %s\n' "$C_DIM" "$C_OFF" "$*"
    else
        "$@"
    fi
}
has_cmd() { command -v "$1" >/dev/null 2>&1; }
# sudo works here only with a terminal (password prompt) or cached credentials;
# boot/cron runs must never hang waiting for a password.
can_sudo() { [[ -t 0 ]] || sudo -n true 2>/dev/null; }
apt_ensure() {
    local pkg missing=()
    for pkg in "$@"; do dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg"); done
    [[ ${#missing[@]} -eq 0 ]] && { skip "apt: nothing to install (${*})."; return 0; }
    if [[ "$DRY_RUN" == true ]]; then
        printf '%s  would install:%s %s\n' "$C_DIM" "$C_OFF" "${missing[*]}"; return 0
    fi
    if ! can_sudo; then
        warn "sudo unavailable (non-interactive) — skipped apt install: ${missing[*]}"; return 0
    fi
    step "apt: installing ${missing[*]}"
    sudo apt-get update -qq || warn "apt update reported errors — continuing."
    sudo apt-get install -y "${missing[@]}"
}
clone_or_pull() {
    local url="$1" dest="$2"
    if [[ -d "$dest/.git" ]]; then
        run git -C "$dest" pull --ff-only --quiet || warn "Could not pull $dest — leaving as-is."
    elif [[ -e "$dest" ]]; then
        warn "$dest exists but is not a git checkout — leaving untouched."
    else
        step "Cloning $url → $dest"
        run git clone --quiet "$url" "$dest"
    fi
}
ensure_source_line() {
    local line="$1" file="$2"
    if [[ -f "$file" ]] && grep -qxF "$line" "$file"; then
        skip "$file already wired."
        return
    fi
    if [[ -s "$file" ]]; then
        local backup="$file.backup.$$"
        warn "$file exists — backing up to $backup"
        run cp "$file" "$backup"
    fi
    if [[ "$DRY_RUN" == true ]]; then
        printf '%s  would write:%s %s → %s\n' "$C_DIM" "$C_OFF" "$line" "$file"
    else
        printf '%s\n' "$line" > "$file"
    fi
    ok "wired $file"
}

# ── Install ──────────────────────────────────────────────────────────────────
title "Tmux"
[[ "$REPO" != "$HOME/.tmuxrc" ]] && warn "Repo expected at ~/.tmuxrc (found $REPO) — ~/.tmux.conf still points at ~/.tmuxrc."

apt_ensure tmux git xclip jq

# Point ~/.tmux.conf at this repo.
ensure_source_line "source-file ~/.tmuxrc/config" "$HOME/.tmux.conf"

# TPM — the plugin manager the config drives.
clone_or_pull https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# Install plugins non-interactively if TPM ships its installer.
tpm_install="$HOME/.tmux/plugins/tpm/bin/install_plugins"
if [[ -x "$tpm_install" ]]; then
    step "Installing tmux plugins via TPM"
    run "$tpm_install" >/dev/null 2>&1 || warn "TPM install failed — inside tmux press: prefix + I"
    ok "tmux plugins installed."
else
    warn "TPM installer not found — inside tmux press: prefix + I (backtick + I)."
fi

# Reload: apply the config to any running tmux server right now.
if tmux info >/dev/null 2>&1; then
    step "Reloading running tmux"
    run tmux source-file "$HOME/.tmux.conf" || warn "tmux reload failed."
    ok "tmux reloaded."
else
    skip "No running tmux server — config loads on next start."
fi

ok "Tmux ready."

# ── AI-agent status markers ──────────────────────────────────────────────────
# name_windows.sh paints a status marker from the @agent_state pane option, but
# something has to *set* that option. The reporting side lives in each agent's
# own config, outside this repo — so wire it up from here, per agent, and only
# for agents that are actually installed. Skipping an absent agent is a no-op,
# so this stays safe to run on any machine.
title "AI agent status"

AGENT_STATE_SH="$REPO/scripts/agent_state.sh"

# Rebuild our hook entries from agents/claude-hooks.json (event -> [script,
# args...] under scripts/), after dropping any we wrote previously. Re-running
# never duplicates, and hooks the user added themselves are carried through
# untouched. The strip pattern matches by script name, so entries written by an
# older layout - or by a checkout at a different path - are still recognised.
CLAUDE_JQ='
  def strip_ours:
    with_entries(
      .value |= ( map(.hooks |= map(select((.command // "") | test("agent_(state|notify)\\.sh") | not)))
                | map(select((.hooks | length) > 0)) )
    )
    | with_entries(select((.value | length) > 0));

  ($map[0]
   | del(.["_comment"])
   | with_entries(.value = [{ hooks: [{ type: "command",
                                        command: ([$dir + "/" + .value[0]] + .value[1:] | join(" ")),
                                        async: true }] }])) as $ours
  | .hooks = ((.hooks // {}) | strip_ours)
  | reduce ($ours | to_entries[]) as $e (.; .hooks[$e.key] += $e.value)
'

wire_claude() {
    local settings="$HOME/.claude/settings.json"
    local map="$REPO/agents/claude-hooks.json"
    local current new

    current="$([[ -f "$settings" ]] && cat "$settings" || echo '{}')"

    if ! new="$(printf '%s' "$current" |
                jq --arg dir "$REPO/scripts" --slurpfile map "$map" "$CLAUDE_JQ" 2>/dev/null)"; then
        warn "claude: $settings is not valid JSON — left untouched."
        return
    fi

    # Compare normalised forms so a re-run that changes nothing writes nothing
    # (Claude Code watches this file and reloads on every write).
    if [[ "$(printf '%s' "$current" | jq -S .)" == "$(printf '%s' "$new" | jq -S .)" ]]; then
        skip "claude: status hooks already wired."
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        printf '%s  would write:%s status hooks → %s\n' "$C_DIM" "$C_OFF" "$settings"
        return
    fi

    mkdir -p "$(dirname "$settings")"
    [[ -f "$settings" ]] && cp "$settings" "$settings.backup.$$"
    printf '%s\n' "$new" > "$settings.tmp.$$" && mv "$settings.tmp.$$" "$settings"
    ok "claude: status hooks wired into $settings"
}

wire_opencode() {
    local src="$REPO/agents/opencode-tmux-status.js"
    local dir rendered

    rendered="$(sed "s|__AGENT_STATE_SH__|$AGENT_STATE_SH|" "$src")"

    # opencode's docs disagree with themselves on plugin/ vs plugins/, so drop
    # the file in both — the unused one is inert.
    for dir in "$HOME/.config/opencode/plugin" "$HOME/.config/opencode/plugins"; do
        local dest="$dir/tmux-status.js"
        if [[ -f "$dest" ]] && [[ "$(cat "$dest")" == "$rendered" ]]; then
            skip "opencode: plugin already current at $dest"
            continue
        fi
        if [[ "$DRY_RUN" == true ]]; then
            printf '%s  would write:%s %s\n' "$C_DIM" "$C_OFF" "$dest"
            continue
        fi
        mkdir -p "$dir"
        printf '%s\n' "$rendered" > "$dest"
        ok "opencode: plugin installed at $dest"
    done
}

if ! has_cmd jq; then
    warn "jq not installed — skipped agent status wiring (install jq, then re-run)."
else
    if has_cmd claude || [[ -d "$HOME/.claude" ]]; then
        wire_claude
    else
        skip "claude not installed — no hooks to wire."
    fi

    if has_cmd opencode || [[ -d "$HOME/.config/opencode" ]]; then
        wire_opencode
    else
        skip "opencode not installed — no plugin to wire."
    fi
fi

ok "Agent status ready."
