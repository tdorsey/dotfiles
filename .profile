# POSIX Login Shell Entry Point
# This file is the canonical root for shell initialization
# Sourced by login shells (sh, dash, bash, zsh)
# Prevent double loading
[ -n "$__PROFILE_LOADED" ] && return
__PROFILE_LOADED=1

# =============================================================================
# XDG Base Directory Setup (must be first!)
# =============================================================================
if [ -z "$XDG_CONFIG_HOME" ]; then
    export XDG_CONFIG_HOME="$HOME/.config/dotfiles"
fi
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"
DOTFILES_DIR="$XDG_CONFIG_HOME"

# =============================================================================
# Load environment
# =============================================================================
if [ -f "$DOTFILES_DIR/env.sh" ]; then
    . "$DOTFILES_DIR/env.sh"
fi

# =============================================================================
# Login-only setup (only runs once per login session)
# =============================================================================
# Skip if inside tmux - tmux panes should not trigger login-once
if [ -z "$TMUX" ] && [ -z "$__LOGIN_ONCE_DONE" ]; then
    __LOGIN_ONCE_DONE=1
    if [ -f "$DOTFILES_DIR/login-once.sh" ]; then
        . "$DOTFILES_DIR/login-once.sh"
    fi
fi

# =============================================================================
# Interactive shell setup
# =============================================================================
# Only proceed if interactive
case $- in
    *i*) ;;
    *) return;;
esac

if [ -f "$DOTFILES_DIR/interactive.sh" ]; then
    . "$DOTFILES_DIR/interactive.sh"
fi
