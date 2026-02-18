# Product Requirements Document (PRD)

## Portable, POSIX-First Shell Startup & Dotfiles Architecture

---

## 1. Overview

This document defines a portable, maintainable, and idempotent shell startup architecture for Unix-like systems. The goal is to create a **POSIX-first dotfiles layout** that:

* Works across `sh`, `dash`, `bash`, `zsh`
* Cleanly separates login / interactive / non-interactive behavior
* Avoids repeated initialization in subshells
* Works correctly inside **tmux**
* Avoids shell-specific lock-in
* Scales cleanly as dotfiles grow
* Uses **XDG Base Directory Specification** for configuration location

Fish and other non-POSIX shells are out of scope by default and may be layered separately.

---

## 2. Goals

### Functional Goals

1. Single canonical entry point.
2. Clear separation of:

   * Environment setup
   * Login-once initialization
   * Interactive configuration
3. Idempotent loading (safe to source multiple times).
4. No PATH duplication.
5. Fast startup in subshells and tmux panes.
6. Strict POSIX compatibility in shared files.

### Non-Goals

* Supporting Fish via shared syntax.
* Using shell-specific feature systems (e.g., Bash `shopt`, Zsh `setopt`) in shared layers.
* Replacing shell-specific RC files entirely.

---

## 3. Design Principles

### 3.1 POSIX First

`~/.profile` is the only user startup file defined by POSIX. It is the canonical root.

All portable configuration flows from it.

### 3.2 Idempotence

Every layer must be safe to source multiple times.

Use guard variables:

* `__PROFILE_LOADED`
* `__INTERACTIVE_LOADED`
* `__LOGIN_ONCE_DONE`

### 3.3 Layered Responsibilities

| Layer            | Responsibility        | Shell Support    |
| ---------------- | -------------------- | ---------------- |
| `env.sh`         | Environment variables | POSIX            |
| `login-once.sh`  | Once-per-login tasks  | POSIX            |
| `interactive.sh` | Terminal-only setup   | POSIX            |
| `aliases.sh`     | Aliases               | POSIX            |
| `functions.sh`   | Shell functions       | bash/zsh         |
| `ssh_agent.sh`   | SSH agent + tmux     | bash/zsh         |

---

## 4. Reference Dotfiles Layout

### 4.1 XDG Base Directory

This project follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/):

| Variable           | Default             | Our Value                        |
| ------------------ | ------------------- | -------------------------------- |
| `$XDG_CONFIG_HOME` | `$HOME/.config`    | `$HOME/.config` (standard)       |
| `$XDG_DATA_HOME`   | `$HOME/.local/share` | -                              |
| `$XDG_STATE_HOME`  | `$HOME/.local/state` | -                              |
| `$XDG_CACHE_HOME`  | `$HOME/.cache`     | -                                |

### 4.2 Directory Structure

```
$HOME/
├── .profile              # POSIX login shell entry
├── .shrc                 # Bridge for POSIX sh ($ENV target)
├── .bashrc               # Bridge for bash
├── .zshrc                # Bridge for zsh
└── .config/
    └── dotfiles/
        ├── env.sh
        ├── login-once.sh
        ├── interactive.sh
        ├── aliases.sh
        ├── functions.sh
        └── ssh_agent.sh
```

This layout ensures:

* Clean modular separation
* Minimal logic in top-level files
* Easy portability across systems
* XDG-compliant configuration location

---

## 5. Boot Flow Specification

### 5.1 XDG Configuration Setup

The `.profile` file must set `$XDG_CONFIG_HOME` to the standard location before sourcing any configuration:

```sh
# Set XDG Base Directory (must be first)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"
```

### 5.2 Login Shell

1. System reads `/etc/profile`
2. Shell reads `~/.profile`
3. `env.sh` loads
4. `login-once.sh` runs (once per login session)
5. If interactive → `interactive.sh`

### 5.2 Non-Login Interactive Shell

Triggered by:

* New terminal tab
* Subshell
* tmux pane

Flow:

1. `.bashrc` or `.zshrc` sources `.profile`
2. Guards prevent login-only logic
3. `interactive.sh` loads once

### 5.3 Non-Interactive Shell

Example:

```
sh script.sh
```

Flow:

* `.profile` may load environment
* Interactive logic is skipped
* No prompt, aliases, or heavy setup

---

## 6. Canonical File Definitions

---

### 6.1 `~/.profile`

Strictly POSIX. This is the entry point for login shells.

```sh
# POSIX-compliant login shell entry
# This file must work with sh, dash, bash, zsh

# Prevent double loading
[ -n "$__PROFILE_LOADED" ] && return
__PROFILE_LOADED=1

# =============================================================================
# XDG Base Directory Setup (must be first!)
# =============================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"

# Define DOTFILES_DIR for convenience
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
```

### 6.2 `$DOTFILES_DIR/env.sh`

Portable environment variables only. POSIX-compliant.

```sh
# Prevent double loading
[ -n "$__ENV_LOADED" ] && return
__ENV_LOADED=1

# Ensure PATH is not duplicated
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
# XDG-Compliant Paths
# =============================================================================
# These can be used by applications that support XDG
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
```

Constraints:

* No aliases
* No prompt
* No interactive detection
* No shell-specific features

---

### 6.3 `login-once.sh`

Runs once per OS login (not per tmux pane). This is where SSH agent initialization belongs.

```sh
# Prevent double loading
[ -n "$__LOGIN_ONCE_LOADED" ] && return
__LOGIN_ONCE_LOADED=1

# =============================================================================
# SSH Agent Management
# =============================================================================
# Single ssh-agent for entire session (all tmux panes share it)

# Source SSH agent functions if available
if [ -f "$DOTFILES_DIR/ssh_agent.sh" ]; then
    . "$DOTFILES_DIR/ssh_agent.sh"
    ensure_ssh_agent
fi

# =============================================================================
# Other once-per-login tasks
# =============================================================================
# Add session-wide initialization here
```

Appropriate for:

* SSH agent startup
* Session-wide variables
* One-time expensive setup
* GPG agent startup

Not appropriate for:

* Aliases
* Prompt
* Completion systems
* Tmux-specific setup

---

### 6.4 `interactive.sh`

Interactive-only logic. This is where aliases, functions, and tmux sync belong.

```sh
# Prevent double loading
[ -n "$__INTERACTIVE_LOADED" ] && return
__INTERACTIVE_LOADED=1

# =============================================================================
# Load aliases (POSIX)
# =============================================================================
if [ -f "$DOTFILES_DIR/aliases.sh" ]; then
    . "$DOTFILES_DIR/aliases.sh"
fi

# =============================================================================
# Load functions (bash/zsh only)
# =============================================================================
if [ -f "$DOTFILES_DIR/functions.sh" ]; then
    . "$DOTFILES_DIR/functions.sh"
fi

# =============================================================================
# Load SSH agent functions and sync (bash/zsh only)
# =============================================================================
if [ -f "$DOTFILES_DIR/ssh_agent.sh" ]; then
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
```

Appropriate for:

* Prompt
* Aliases
* Functions
* Completions
* Tool initialization (nvm, pyenv, etc.)
* Tmux environment sync

---

### 6.5 Shell Bridge Files

#### `~/.shrc` (POSIX sh via $ENV)

```sh
# For POSIX sh: export ENV="$HOME/.shrc" in .profile
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
```

#### `~/.bashrc` (bash)

```sh
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
```

#### `~/.zshrc` (zsh)

```sh
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
```

This ensures consistent behavior across login and non-login shells.

---

### 6.6 SSH Agent (`ssh_agent.sh`)

SSH agent management with tmux synchronization. **bash/zsh only** (uses arrays).

```sh
# SSH Agent Management Functions
# Requires: bash or zsh (uses arrays)
# Must be sourced after env.sh sets DOTFILES_DIR

# Prevent double loading
[ -n "$__SSH_AGENT_LOADED" ] && return
__SSH_AGENT_LOADED=1

# Configuration
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
```

**Key Features:**

1. **Single Agent**: Kills stale agents before starting new one
2. **Symlink Management**: Uses stable symlink path, resolves to real socket
3. **Tmux Sync**: Propagates SSH_AUTH_SOCK to new tmux panes
4. **Idempotent**: Safe to source multiple times

---

### 6.7 Aliases (`aliases.sh`)

Literal aliases only. POSIX-compliant (works in sh, dash, bash, zsh).

```sh
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
```

Constraints:

* **Only literal aliases** - no functions
* POSIX syntax only: `alias name=value`

---

### 6.8 Functions (`functions.sh`)

Shell functions. **bash/zsh only** (uses arrays).

```sh
# Prevent double loading
[ -n "$__FUNCTIONS_LOADED" ] && return
__FUNCTIONS_LOADED=1

# =============================================================================
# Directory Operations
# =============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# =============================================================================
# File Operations
# =============================================================================

# Truncate file to zero size and open in nano
topen() {
    if [ $# -eq 0 ]; then
        echo "Usage: topen <filename>"
        return 1
    fi
    local file="$1"
    touch "$file"
    truncate --size=0 "$file"
    nano "$file"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Backup a file with timestamp
backup() {
    if [ $# -eq 0 ]; then
        echo "Usage: backup <filename>"
        return 1
    fi
    local file="$1"
    local backup_name="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup_name" && echo "Backed up $file to $backup_name"
}
```

Constraints:

* Functions can use bash/zsh features (arrays, etc.)
* Must work in both bash and zsh

---

## 7. tmux Behavior Model

### 7.1 Requirements

When using **tmux**:

1. Initial login shell loads full environment (including login-once.sh).
2. tmux server inherits environment from starting shell.
3. New panes launch interactive non-login shells.
4. **Critical**: `sync_tmux_ssh_agent()` must be called in each new pane to propagate SSH_AUTH_SOCK.

### 7.2 Behavior Flow

```
1. User logs in (login shell)
   └─> .profile → env.sh → login-once.sh → interactive.sh
       └─> ensure_ssh_agent() starts ssh-agent

2. User starts tmux
   └─> tmux inherits environment from login shell

3. User opens new tmux pane (interactive non-login)
   └─> .bashrc → .profile (guards prevent re-running login-once)
       └─> interactive.sh → sync_tmux_ssh_agent()
       └─> SSH_AUTH_SOCK propagated to new pane
```

### 7.3 Guards Prevent

* PATH duplication
* Re-running login-once logic (checked via `$__LOGIN_ONCE_DONE`)
* Restarting agents (agent persists, just syncs socket)
* Heavy reinitialization

### 7.4 Tmux Configuration (Optional)

For optimal tmux behavior, add to `~/.tmux.conf`:

```sh
# Sync environment variables to new panes
set-option -g update-environment -r

# Keep SSH_AUTH_SOCK in sync
set-option -g update-environment "SSH_AUTH_SOCK SSH_AGENT_PID"
```

Startup remains fast and deterministic.

---

## 8. Portability Constraints

Shared files MUST avoid:

* `[[ ... ]]`
* `source`
* `function name()`
* Arrays
* Bash-only variables
* Zsh-only syntax
* `shopt`
* `setopt`
* `PROMPT_COMMAND`

Use only:

* POSIX `.` for sourcing
* `case`
* `test` / `[ ]`
* simple exports

---

## 9. Extensibility

Future growth areas:

```
$DOTFILES_DIR/
    completion.sh
    tools/
        node.sh
        python.sh
        go.sh
```

These should be sourced only from `interactive.sh`.

---

## 10. Optional Enhancements

### 10.1 Strict POSIX `$ENV` Support

Set in `.profile`:

```sh
ENV="$HOME/.profile"
export ENV
```

Some shells use this for non-login interactive sessions.

Behavior varies; optional.

---

### 10.2 System-Wide Integration

If managing `/etc/profile`, mirror the same structure:

```
/etc/profile.d/shell-env.sh
```

Keep logic identical and idempotent.

---

## 11. Performance Expectations

* Login shell: full initialization.
* Subshell: <50ms expected.
* tmux pane: minimal overhead.
* No exponential PATH growth.
* No duplicated agents.

---

## 12. Success Criteria

* No duplicate PATH entries after repeated subshell launches.
* No repeated agent startups.
* Identical environment inside and outside tmux.
* Compatible with `sh`, `dash`, `bash`, `zsh`.
* All shared files pass `dash -n` syntax check.

---

## 13. Testing with Bats

### 13.1 Test Files

Tests should be located alongside the modules they test:

```
$DOTFILES_DIR/
├── env.sh
├── login-once.sh
├── interactive.sh
├── aliases.sh
├── functions.sh
├── ssh_agent.sh
└── test/
    ├── test_env.bats
    ├── test_aliases.bats
    ├── test_functions.bats
    └── test_ssh_agent.bats
```

### 13.2 Running Tests

```bash
# Install bats
npm install -g bats

# Run all tests
bats $DOTFILES_DIR/test/

# Run specific test
bats $DOTFILES_DIR/test/test_ssh_agent.bats
```

### 13.3 Example Test: SSH Agent

```bash
#!/usr/bin/env bats

setup() {
    source "$DOTFILES_DIR/ssh_agent.sh"
}

@test "SSH_ENV variable is defined" {
    [ -n "$SSH_ENV" ]
}

@test "SSH_SOCK_LINK variable is defined" {
    [ -n "$SSH_SOCK_LINK" ]
}

@test "kill_stale_agents function exists" {
    type kill_stale_agents &>/dev/null
}

@test "ensure_ssh_agent starts ssh-agent" {
    ensure_ssh_agent
    pgrep -x ssh-agent > /dev/null
}

@test "SSH_AUTH_SOCK resolves to real path" {
    ensure_ssh_agent
    if [ -L "$SSH_SOCK_LINK" ]; then
        local resolved
        resolved="$(readlink -f "$SSH_SOCK_LINK")"
        [ "$SSH_AUTH_SOCK" = "$resolved" ]
    fi
}
```

---

## 14. Summary

This architecture provides:

* POSIX-compliant core
* XDG Base Directory Specification compliance
* Clean login/interactive separation
* tmux-safe idempotence
* Modular dotfiles layout
* Shell-agnostic portability (sh, dash, bash, zsh)
* SSH agent management with tmux synchronization
* Testable shell modules via bats

It establishes a durable, scalable baseline suitable for professional environments, multi-machine sync, and long-term maintenance.

---

## 15. Implementation

### 15.1 Git Setup

```bash
# Initialize repo in homedir (if not already)
cd /homedir
git init

# Create worktree for implementation
git worktree add ../dotfiles-worktree -b feat/dotfiles-xdg

# Work in the worktree
cd ../dotfiles-worktree
```

### 15.2 Implementation Process

1. **Stash** any current work before implementing
2. **Commit PRD** to new branch first
3. **Implement each task** with atomic commits
4. **Use `verification-before-completion`** superpower before claiming completion
5. **Update this PRD** with task status after each phase

### 15.3 Task Checklist

| Task | Description | Status |
|------|-------------|--------|
| **Phase 1: Create Structure** | | |
| 1.1 | Create `$HOME/.config/dotfiles/` directory | [x] |
| 1.2 | Create `env.sh` - environment variables | [x] |
| 1.3 | Create `login-once.sh` - login-only init | [x] |
| 1.4 | Create `interactive.sh` - interactive setup | [x] |
| 1.5 | Create `aliases.sh` - POSIX aliases | [x] |
| 1.6 | Create `functions.sh` - bash/zsh functions | [x] |
| 1.7 | Create `ssh_agent.sh` - SSH + tmux sync | [x] |
| **Phase 2: Bridge Files** | | |
| 2.1 | Create `~/.profile` - POSIX login entry | [x] |
| 2.2 | Create `~/.shrc` - POSIX sh bridge | [x] |
| 2.3 | Create `~/.bashrc` - bash bridge | [x] |
| 2.4 | Create `~/.zshrc` - zsh bridge | [x] |
| **Phase 3: Tests** | | |
| 3.1 | Create `test/test_env.bats` | [x] |
| 3.2 | Create `test/test_aliases.bats` | [x] |
| 3.3 | Create `test/test_functions.bats` | [x] |
| 3.4 | Create `test/test_ssh_agent.bats` | [x] |
| **Phase 4: Verification** | | |
| 4.1 | Run all bats tests | [x] |
| 4.2 | Verify shell startup works | [x] |
| 4.3 | Verify XDG_CONFIG_HOME set correctly | [x] |
| 4.4 | Verify SSH agent functions | [x] |
| 4.5 | Verify tmux sync functions | [x] |

### 15.4 Commit Convention

Each task should be committed atomically:

```bash
git add <files>
git commit -m "<type>: <description>

<optional body>

<optional footer>"
```

Types:
- `feat`: New feature (minor)
- `fix`: Bug fix (patch)
- `chore`: Maintenance/tooling
- `docs`: Documentation
- `test`: Tests

### 15.5 Verification Requirements

Before claiming completion, verify:

- [ ] All bats tests pass
- [ ] Shell startup works without errors
- [ ] `$XDG_CONFIG_HOME` properly set to `$HOME/.config/dotfiles`
- [ ] SSH agent starts and persists
- [ ] Tmux sync propagates `SSH_AUTH_SOCK`
- [ ] No duplicate PATH entries after repeated subshell launches
- [ ] All POSIX files pass `dash -n` syntax check

Use the **`verification-before-completion`** superpower for thorough validation.

---

If desired, a companion document can specify:

* macOS terminal behavior nuances
* Linux distro-specific behavior
* Enterprise multi-user deployment patterns
* Git-based dotfiles deployment strategy
