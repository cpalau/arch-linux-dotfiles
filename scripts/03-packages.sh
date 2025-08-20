#!/bin/bash

# 02-packages.sh - Package Installation Script for Arch Linux
# Installs packages from pacman directory (official repositories)
# Created by: Cristian Palau

# Exit on any error
set -e

# Get script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utility functions
source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/logging.sh" 
source "$SCRIPT_DIR/utils/helpers.sh"

# Configuration
PACKAGES_DIR="$PROJECT_ROOT/packages/pacman"
INSTALL_LOG="$PROJECT_ROOT/install_packages.log"

# Package categories in installation order
CATEGORIES=("base" "development" "desktop" "optional")

# Statistics tracking
TOTAL_PACKAGES=0
INSTALLED_PACKAGES=0
FAILED_PACKAGES=0
SKIPPED_PACKAGES=0

# Initialize logging
init_package_logging() {
    log_step "Initializing package installation logging..."
    echo "=== Package Installation Log - $(date) ===" > "$INSTALL_LOG"
    log_success "Package installation log initialized: $INSTALL_LOG"
}

# Parse package file and extract package names
parse_package_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "Package file not found: $file_path"
        return 1
    fi
    
    # Extract lines that start with "- " and get package name
    # Filter out comments (lines starting with #) and empty lines
    grep "^- " "$file_path" 2>/dev/null | sed 's/^- //' | sed 's/[[:space:]]*$//' || true
}

# Check if package is already installed
is_package_installed() {
    local package="$1"
    pacman -Qi "$package" &>/dev/null
}

# Install individual package with error handling
install_package() {
    local package="$1"
    local category="$2"
    
    log_info "Installing package: $package (from $category)"
    echo "$(date): Installing $package from $category" >> "$INSTALL_LOG"
    
    # Check if already installed
    if is_package_installed "$package"; then
        log_success "Package $package is already installed (skipping)"
        echo "$(date): SKIPPED - $package already installed" >> "$INSTALL_LOG"
        ((SKIPPED_PACKAGES++))
        return 0
    fi
    
    # Install package
    if pacman -S --noconfirm --needed "$package" >> "$INSTALL_LOG" 2>&1; then
        log_success "Successfully installed: $package"
        echo "$(date): SUCCESS - $package installed" >> "$INSTALL_LOG"
        ((INSTALLED_PACKAGES++))
        return 0
    else
        local exit_code=$?
        log_error "Failed to install package: $package (exit code: $exit_code)"
        echo "$(date): ERROR - Failed to install $package (exit code: $exit_code)" >> "$INSTALL_LOG"
        ((FAILED_PACKAGES++))
        return $exit_code
    fi
}

# Install all packages from a category file
install_category() {
    local category="$1"
    local file_path="$PACKAGES_DIR/${category}.txt"
    
    log_step "Installing packages from category: $category"
    
    if [[ ! -f "$file_path" ]]; then
        log_warn "Category file not found: $file_path (skipping)"
        return 0
    fi
    
    # Parse packages from file
    local packages
    packages=$(parse_package_file "$file_path")
    
    if [[ -z "$packages" ]]; then
        log_warn "No packages found in category: $category"
        return 0
    fi
    
    # Count packages in this category
    local category_count
    category_count=$(echo "$packages" | wc -l)
    log_info "Found $category_count packages in $category category"
    
    # Install each package
    local package_num=1
    while IFS= read -r package; do
        if [[ -n "$package" ]]; then
            log_info "[$package_num/$category_count] Processing: $package"
            
            if ! install_package "$package" "$category"; then
                log_error "Package installation failed: $package"
                log_error "Aborting installation process due to failure"
                echo "$(date): ABORT - Installation process terminated due to failure in $package" >> "$INSTALL_LOG"
                return 1
            fi
            
            ((TOTAL_PACKAGES++))
            ((package_num++))
        fi
    done <<< "$packages"
    
    log_success "Category '$category' installation completed successfully"
    echo "$(date): CATEGORY COMPLETE - $category" >> "$INSTALL_LOG"
}

# Update package database
update_package_database() {
    log_step "Updating package database..."
    echo "$(date): Updating package database" >> "$INSTALL_LOG"
    
    if pacman -Sy >> "$INSTALL_LOG" 2>&1; then
        log_success "Package database updated successfully"
        echo "$(date): SUCCESS - Package database updated" >> "$INSTALL_LOG"
    else
        log_error "Failed to update package database"
        echo "$(date): ERROR - Failed to update package database" >> "$INSTALL_LOG"
        return 1
    fi
}

# Pre-installation validation
validate_environment() {
    log_step "Validating environment for package installation..."
    
    # Check if running as root
    if ! is_root; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Check network connectivity
    if ! check_network_connection; then
        log_error "No network connection available"
        log_error "Package installation requires internet connectivity"
        exit 1
    fi
    
    # Check if pacman is available
    if ! command_exists pacman; then
        log_error "pacman command not found"
        log_error "This script is designed for Arch Linux systems"
        exit 1
    fi
    
    # Check packages directory
    if [[ ! -d "$PACKAGES_DIR" ]]; then
        log_error "Packages directory not found: $PACKAGES_DIR"
        exit 1
    fi
    
    log_success "Environment validation completed"
}

# Display installation summary
show_installation_summary() {
    log_step "Installation Summary"
    echo
    echo "======================== INSTALLATION SUMMARY ========================"
    echo "Total packages processed: $TOTAL_PACKAGES"
    echo "Successfully installed:   $INSTALLED_PACKAGES"
    echo "Already installed:        $SKIPPED_PACKAGES"
    echo "Failed installations:     $FAILED_PACKAGES"
    echo "===================================================================="
    echo
    echo "Detailed log available at: $INSTALL_LOG"
    
    # Add summary to log
    {
        echo "=== INSTALLATION SUMMARY - $(date) ==="
        echo "Total packages processed: $TOTAL_PACKAGES"
        echo "Successfully installed: $INSTALLED_PACKAGES" 
        echo "Already installed: $SKIPPED_PACKAGES"
        echo "Failed installations: $FAILED_PACKAGES"
        echo "=== END SUMMARY ==="
    } >> "$INSTALL_LOG"
    
    if [[ $FAILED_PACKAGES -eq 0 ]]; then
        log_success "All package installations completed successfully!"
        return 0
    else
        log_error "Some package installations failed. Check the log for details."
        return 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Performing cleanup..."
    
    # Clean package cache if installation was successful
    if [[ $FAILED_PACKAGES -eq 0 ]]; then
        log_step "Cleaning package cache..."
        if pacman -Sc --noconfirm >> "$INSTALL_LOG" 2>&1; then
            log_success "Package cache cleaned"
        else
            log_warn "Failed to clean package cache (non-critical)"
        fi
    fi
}

# Main execution function
main() {
    log_step "Starting Arch Linux Package Installation"
    log_info "Installing packages from official repositories (pacman)"
    
    # Initialize
    init_package_logging
    validate_environment
    
    # Update package database
    update_package_database
    
    # Install packages by category
    for category in "${CATEGORIES[@]}"; do
        log_step "Processing category: $category"
        
        if ! install_category "$category"; then
            log_error "Category '$category' installation failed"
            show_installation_summary
            exit 1
        fi
        
        log_success "Category '$category' completed successfully"
        echo "---"
    done
    
    # Cleanup and summary
    cleanup
    show_installation_summary
}

# Trap to handle interruptions
trap 'log_error "Installation interrupted by user"; show_installation_summary; exit 1' INT TERM

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi