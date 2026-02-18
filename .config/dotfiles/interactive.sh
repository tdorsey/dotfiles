# Interactive Shell Script
# Interactive-only logic
# POSIX-compliant for sourcing, but may load bash/zsh specific files
# Prevent double loading
[ -n "$__INTERACTIVE_LOADED" ] && return
__INTERACTIVE_LOADED=1

# Source environment first (for DOTFILES_DIR)
if [ -n "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/env.sh" ]; then
    . "$DOTFILES_DIR/env.sh"
fi

# =============================================================================
# Load aliases (POSIX)
# =============================================================================
if [ -n "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/aliases.sh" ]; then
    . "$DOTFILES_DIR/aliases.sh"
fi

# =============================================================================
# Load functions (bash/zsh only)
# =============================================================================
if [ -n "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/functions.sh" ]; then
    . "$DOTFILES_DIR/functions.sh"
fi

# =============================================================================
# Load SSH agent functions and sync (bash/zsh only)
# =============================================================================
if [ -n "$DOTFILES_DIR" ] && [ -f "$DOTFILES_DIR/ssh_agent.sh" ]; then
    . "$DOTFILES_DIR/ssh_agent.sh"
    sync_tmux_ssh_agent
fi

# =============================================================================
# Tool initialization (nvm, pyenv, etc.)
# =============================================================================
# These are typically bash/zsh specific
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"
fi

# =============================================================================
# Prompt
# =============================================================================
PS1='[\u@\h \W]\$ '
export PS1
