#!/usr/bin/env bats

# Test env.sh module
# POSIX compliance tests

setup() {
    export HOME="/homedir"
    export DOTFILES_DIR="$HOME/.config/dotfiles"
    load "$DOTFILES_DIR/env.sh"
}

@test "XDG_CONFIG_HOME is set" {
    [ -n "$XDG_CONFIG_HOME" ]
}

@test "XDG_CONFIG_HOME points to dotfiles" {
    [ "$XDG_CONFIG_HOME" = "$HOME/.config/dotfiles" ]
}

@test "DOTFILES_DIR is set" {
    [ -n "$DOTFILES_DIR" ]
}

@test "DOTFILES_DIR equals XDG_CONFIG_HOME" {
    [ "$DOTFILES_DIR" = "$XDG_CONFIG_HOME" ]
}

@test "PATH contains HOME/bin" {
    case ":$PATH:" in
        *":$HOME/bin:"*) ;;
        *) return 1 ;;
    esac
}

@test "EDITOR is set" {
    [ -n "$EDITOR" ]
}

@test "PAGER is set" {
    [ -n "$PAGER" ]
}

@test "NVM_DIR is set" {
    [ -n "$NVM_DIR" ]
}

@test "XDG_DATA_HOME is set" {
    [ -n "$XDG_DATA_HOME" ]
}

@test "XDG_STATE_HOME is set" {
    [ -n "$XDG_STATE_HOME" ]
}

@test "XDG_CACHE_HOME is set" {
    [ -n "$XDG_CACHE_HOME" ]
}

@test "env.sh guard prevents reloading" {
    run bash -c "source $DOTFILES_DIR/env.sh; echo \$__ENV_LOADED"
    [ "$output" = "1" ]
}
