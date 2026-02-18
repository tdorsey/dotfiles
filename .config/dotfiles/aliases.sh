# Aliases
# POSIX-compliant - literal aliases only
# Prevent double loading
[ -n "$__ALIASES_LOADED" ] && return
__ALIASES_LOADED=1

# =============================================================================
# File Operations
# =============================================================================
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# =============================================================================
# Docker Operations
# =============================================================================
alias dc='docker compose'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcl='docker compose logs'
alias dcp='docker compose ps'
alias dcr='docker compose restart'
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dv='docker volume ls'
alias dn='docker network ls'
alias dprune='docker system prune -f'
alias dprunea='docker system prune -af'

# =============================================================================
# Git Operations
# =============================================================================
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias gdc='git diff --cached'
alias gpl='git pull'

# =============================================================================
# System Operations
# =============================================================================
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias psg='ps aux | grep -v grep | grep'
alias ports='netstat -tulanp'
alias dusage='du -sh * | sort -rh'

# =============================================================================
# Text Processing
# =============================================================================
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ff='find . -name'
alias fd='find . -type d -name'

# =============================================================================
# Development
# =============================================================================
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias pytest='python3 -m pytest'
alias serve='python3 -m http.server'
alias serve8000='python3 -m http.server 8000'
