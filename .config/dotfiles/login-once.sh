# Login-Once Shell Script
# Runs once per OS login (not per tmux pane)
# POSIX-compliant - no bash/zsh specific features
# Prevent double loading
[ -n "$__LOGIN_ONCE_LOADED" ] && return
__LOGIN_ONCE_LOADED=1

# Source environment first (for DOTFILES_DIR)
if [ -n "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/env.sh" ]; then
    . "$DOTFILES_DIR/env.sh"
fi

# =============================================================================
# SSH Agent Management
# =============================================================================
# Single ssh-agent for entire session (all tmux panes share it)
# Source SSH agent functions if available
if [ -n "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/ssh_agent.sh" ]; then
    . "$DOTFILES_DIR/ssh_agent.sh"
    ensure_ssh_agent
fi

# =============================================================================
# Other once-per-login tasks
# =============================================================================
# Add session-wide initialization here
