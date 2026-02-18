#!/usr/bin/env bats

# Test aliases.sh module

setup() {
    export HOME="/homedir"
    export DOTFILES_DIR="$HOME/.config/dotfiles"
    load "$DOTFILES_DIR/aliases.sh"
}

@test "ll alias is defined" {
    alias ll
}

@test "la alias is defined" {
    alias la
}

@test "gs alias is defined" {
    alias gs
}

@test "ga alias is defined" {
    alias ga
}

@test "gc alias is defined" {
    alias gc
}

@test "gp alias is defined" {
    alias gp
}

@test "d alias is defined" {
    alias d
}

@test "dc alias is defined" {
    alias dc
}

@test "df alias is defined" {
    alias df
}

@test "grep alias is defined" {
    alias grep
}

@test "py alias is defined" {
    alias py
}

@test "aliases.sh guard prevents reloading" {
    run bash -c "source $DOTFILES_DIR/aliases.sh; echo \$__ALIASES_LOADED"
    [ "$output" = "1" ]
}
