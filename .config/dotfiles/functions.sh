# Functions
# bash/zsh only (uses arrays)
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
