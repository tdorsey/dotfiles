#!/usr/bin/env bats

# Test functions.sh module (bash/zsh)

setup() {
    export HOME="/homedir"
    export DOTFILES_DIR="$HOME/.config/dotfiles"
    load "$DOTFILES_DIR/functions.sh"
}

@test "mkcd function exists" {
    type mkcd
}

@test "topen function exists" {
    type topen
}

@test "extract function exists" {
    type extract
}

@test "backup function exists" {
    type backup
}

@test "functions.sh guard prevents reloading" {
    run bash -c "source $DOTFILES_DIR/functions.sh; echo \$__FUNCTIONS_LOADED"
    [ "$output" = "1" ]
}
