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

# Check internet connectivity using archlinux.org
check_internet() {
    if ping -c 3 -W 5 archlinux.org &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if ethernet connection is active and can reach archlinux.org
check_ethernet_connection() {
    # First check if any ethernet interface is up and has an IP address
    local eth_interfaces=$(ip link show | grep -E '^[0-9]+: (en|eth)' | cut -d: -f2 | tr -d ' ')
    local ethernet_available=false
    
    for interface in $eth_interfaces; do
        # Check if interface is up
        if ip link show "$interface" | grep -q "state UP"; then
            # Check if interface has an IP address
            if ip addr show "$interface" | grep -q "inet "; then
                log_info "Ethernet interface $interface is active with IP address"
                ethernet_available=true
                break
            fi
        fi
    done
    
    # If no active ethernet interface found, return false
    if [ "$ethernet_available" = false ]; then
        log_info "No active ethernet interfaces found"
        return 1
    fi
    
    # Test connectivity to archlinux.org specifically
    log_info "Testing ethernet connectivity to archlinux.org..."
    if ping -c 3 -W 5 archlinux.org &> /dev/null; then
        log_success "Ethernet connection verified: archlinux.org is reachable"
        return 0
    else
        log_warn "Ethernet interface is active but archlinux.org is not reachable"
        return 1
    fi
}

# Check if any network connection is available (ethernet or wifi)
check_network_connection() {
    if check_ethernet_connection; then
        log_success "Ethernet connection is active"
        return 0
    elif check_internet; then
        log_success "Network connection is active"
        return 0
    else
        return 1
    fi
}