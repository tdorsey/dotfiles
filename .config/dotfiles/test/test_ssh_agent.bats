#!/usr/bin/env bats

# Test ssh_agent.sh module (bash/zsh)

setup() {
    export HOME="/homedir"
    export DOTFILES_DIR="$HOME/.config/dotfiles"
    load "$DOTFILES_DIR/ssh_agent.sh"
}

@test "SSH_ENV variable is defined" {
    [ -n "$SSH_ENV" ]
}

@test "SSH_SOCK_LINK variable is defined" {
    [ -n "$SSH_SOCK_LINK" ]
}

@test "kill_stale_agents function exists" {
    type kill_stale_agents
}

@test "load_ssh_keys function exists" {
    type load_ssh_keys
}

@test "start_agent function exists" {
    type start_agent
}

@test "ensure_ssh_agent function exists" {
    type ensure_ssh_agent
}

@test "sync_tmux_ssh_agent function exists" {
    type sync_tmux_ssh_agent
}

@test "ssh_agent.sh guard prevents reloading" {
    run bash -c "source $DOTFILES_DIR/ssh_agent.sh; echo \$__SSH_AGENT_LOADED"
    [ "$output" = "1" ]
}
