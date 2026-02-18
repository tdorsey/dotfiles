# SSH Agent Management Functions
# Requires: bash or zsh (uses arrays)
# Prevent double loading
[ -n "$__SSH_AGENT_LOADED" ] && return
__SSH_AGENT_LOADED=1

# Configuration
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.config/dotfiles}"
SSH_ENV="${DOTFILES_DIR}/ssh-agent.env"
SSH_SOCK_LINK="${DOTFILES_DIR}/ssh_auth_sock"

# =============================================================================
# Kill all stale ssh-agents except current one
# =============================================================================
kill_stale_agents() {
    local current_pid="${SSH_AGENT_PID:-}"
    local pids
    pids=$(pgrep -x ssh-agent 2>/dev/null) || return 0
    for pid in $pids; do
        [ "$pid" = "$current_pid" ] && continue
        kill "$pid" 2>/dev/null
    done
}

# =============================================================================
# Load SSH keys into agent
# =============================================================================
load_ssh_keys() {
    local keys=()
    for key in ~/.ssh/id_*; do
        [ "${key%.pub}" = "$key" ] || continue
        [ -f "$key" ] || continue
        keys+=("$key")
    done

    if [ ${#keys[@]} -eq 0 ]; then
        echo "No SSH keys found in ~/.ssh/" >&2
        return 0  # Don't fail, just warn
    fi

    ssh-add "${keys[@]}" 2>/dev/null
}

# =============================================================================
# Start new ssh-agent
# =============================================================================
start_agent() {
    kill_stale_agents
    ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
    chmod 600 "$SSH_ENV"
    . "$SSH_ENV"
    ln -sf "$SSH_AUTH_SOCK" "$SSH_SOCK_LINK"
    export SSH_AUTH_SOCK="$(readlink -f "$SSH_SOCK_LINK")"
    load_ssh_keys
}

# =============================================================================
# Ensure ssh-agent is running (reuses existing or starts new)
# =============================================================================
ensure_ssh_agent() {
    export SSH_AUTH_SOCK="$(readlink -f "$SSH_SOCK_LINK" 2>/dev/null)"

    if [ -f "$SSH_ENV" ]; then
        . "$SSH_ENV" > /dev/null
        if kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
            # Agent is running, update symlink
            ln -sf "$(grep SSH_AUTH_SOCK "$SSH_ENV" | cut -d= -f2 | cut -d\; -f1)" "$SSH_SOCK_LINK"
            export SSH_AUTH_SOCK="$(readlink -f "$SSH_SOCK_LINK")"
            load_ssh_keys
        else
            # Agent dead, start new
            kill_stale_agents
            start_agent
        fi
    else
        # No agent env, start new
        kill_stale_agents
        start_agent
    fi
}

# =============================================================================
# Sync SSH_AUTH_SOCK to tmux environment
# =============================================================================
sync_tmux_ssh_agent() {
    if [ -n "$TMUX" ]; then
        # Get the resolved socket path, not the symlink
        local resolved_sock
        resolved_sock="$(readlink -f "$SSH_AUTH_SOCK" 2>/dev/null)"
        if [ -n "$resolved_sock" ]; then
            tmux set-environment SSH_AUTH_SOCK "$resolved_sock"
        fi
    fi
}
