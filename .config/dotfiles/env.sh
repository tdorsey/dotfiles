# Environment Variables
# POSIX-compliant - no bash/zsh specific features
# Prevent double loading
[ -n "$__ENV_LOADED" ] && return
__ENV_LOADED=1

# =============================================================================
# XDG Base Directory Setup (must be first!)
# =============================================================================
# Set XDG_CONFIG_HOME to default if not set
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"

# Define DOTFILES_DIR for convenience
DOTFILES_DIR="$XDG_CONFIG_HOME"

# =============================================================================
# PATH Configuration
# =============================================================================
# Ensure PATH entries are not duplicated
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) PATH="$HOME/bin:$PATH" ;;
esac
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

# =============================================================================
# Application Environment Variables
# =============================================================================
export EDITOR=vi
export PAGER=less

# Docker Compose
export DOCKER_COMPOSE_FILES=/mnt/srv/vscode/git/docker-compose

# CVI (Corrupt Video Inspector)
export CVI_VIDEO_DIR=/mnt/srv/media/movies
export CVI_LOG_DIR="${HOME}/video/logs"
export CVI_OUTPUT_DIR="${HOME}/video/output"

# NVM (Node Version Manager)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# =============================================================================
# XDG-Compliant Paths (for applications that support XDG)
# =============================================================================
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
