#!/bin/bash

# OpenCode installer script - Installs yay and opencode-bin from AUR

# Source utility functions
source "$(dirname "$0")/helpers.sh"
source "$(dirname "$0")/logging.sh"
source "$(dirname "$0")/colors.sh"

# Function to install yay
install_yay() {
    info "Installing yay AUR helper..."
    
    # Install prerequisites
    sudo pacman -S --needed git base-devel || {
        error "Failed to install prerequisites"
        exit 1
    }
    
    # Clone yay-bin repository
    git clone https://aur.archlinux.org/yay-bin.git || {
        error "Failed to clone yay-bin repository"
        exit 1
    }
    
    # Build and install yay-bin
    cd yay-bin
    makepkg -si --noconfirm || {
        error "Failed to build and install yay-bin"
        cd ..
        rm -rf yay-bin
        exit 1
    }
    
    cd ..
    
    # Clean up yay-bin directory
    rm -rf yay-bin
    success "yay installed successfully"
}

# Function to install opencode-bin
install_opencode() {
    info "Updating system and installing opencode-bin..."
    
    # Update system
    yay -Syu --noconfirm || {
        error "Failed to update system"
        exit 1
    }
    
    # Install opencode-bin
    yay -S opencode-bin --noconfirm || {
        error "Failed to install opencode-bin"
        exit 1
    }
    
    success "opencode-bin installed successfully"
}

# Main execution
main() {
    info "Starting OpenCode installation..."
    
    # Check if yay is already installed
    if command -v yay &> /dev/null; then
        info "yay is already installed"
    else
        install_yay
    fi
    
    install_opencode
    
    success "OpenCode installation completed!"
    info "You can now use 'opencode' command"
}

# Run main function
main "$@"