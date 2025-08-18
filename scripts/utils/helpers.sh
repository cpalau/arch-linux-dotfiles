#!/bin/bash

# Helper functions for common tasks
# Created by: Cristian Palau

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if running as root
is_root() {
    [ "$EUID" -eq 0 ]
}

# Check if file exists and source it
source_if_exists() {
    if [ -f "$1" ]; then
        source "$1"
        return 0
    else
        log_error "File not found: $1"
        return 1
    fi
}

# Wait for user confirmation
confirm() {
    local message="${1:-Do you want to continue?}"
    echo -e "${YELLOW}$message [y/N]${NC} "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check internet connectivity
check_internet() {
    if ping -c 3 google.com &> /dev/null; then
        return 0
    else
        return 1
    fi
}