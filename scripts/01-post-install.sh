#!/bin/bash

# Post-installation script for Arch Linux
# Handles user setup and configuration after installation
# Created by: Cristian Palau

set -e  # Exit on any error

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/logging.sh"
source "$SCRIPT_DIR/utils/helpers.sh"

# Configuration
USER_NAME="cristian"
USER_HOME="/home/$USER_NAME"

# Function to create user directory with proper ownership
create_user_directory() {
    local dir_path="$1"
    local description="${2:-directory}"
    
    if [ ! -d "$dir_path" ]; then
        log_info "Creating $description: $dir_path"
        if sudo -u "$USER_NAME" mkdir -p "$dir_path"; then
            log_success "$description created successfully"
            return 0
        else
            log_error "Error creating $description: $dir_path"
            exit 1
        fi
    else
        log_info "$description already exists: $dir_path"
        return 0
    fi
}

# Function to setup directory ownership and permissions
setup_directory_permissions() {
    local dir_path="$1"
    local permissions="${2:-755}"
    
    if [ -d "$dir_path" ]; then
        chown -R "$USER_NAME:$USER_NAME" "$dir_path"
        chmod "$permissions" "$dir_path"
        return 0
    else
        log_error "Directory does not exist: $dir_path"
        exit 1
    fi
}

# Function to create directory structure for development
create_development_structure() {
    log_step "Creating development directory structure..."
    
    # Check if user home directory exists
    if [ ! -d "$USER_HOME" ]; then
        log_error "User home directory $USER_HOME does not exist"
        exit 1
    fi
    
    # Define directories to create
    local directories=(
        "$USER_HOME/development:development directory"
        "$USER_HOME/development/projects:projects directory"
        "$USER_HOME/development/projects/dotfiles:dotfiles directory"
    )
    
    # Create directories
    for dir_info in "${directories[@]}"; do
        IFS=':' read -r dir_path description <<< "$dir_info"
        create_user_directory "$dir_path" "$description"
    done
    
    # Setup permissions for all created directories
    log_step "Setting up directory permissions..."
    for dir_info in "${directories[@]}"; do
        IFS=':' read -r dir_path description <<< "$dir_info"
        setup_directory_permissions "$dir_path"
    done
    
    # Log created structure
    log_success "Directory structure created and configured successfully"
    for dir_info in "${directories[@]}"; do
        IFS=':' read -r dir_path description <<< "$dir_info"
        log_info "✓ $dir_path"
    done
}

# Function to clone a git repository as user
clone_git_repository() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name="${3:-$(basename "$repo_url" .git)}"
    
    local full_path="$target_dir/$repo_name"
    
    # Verify that target directory exists (don't create it automatically)
    if [ ! -d "$target_dir" ]; then
        log_error "Target directory does not exist: $target_dir"
        log_error "The directory where you want to clone must exist before cloning"
        log_error "Make sure the directory structure is created properly first"
        exit 1
    fi
    
    # Check if repository already exists AND has content
    if [ -d "$full_path" ]; then
        # Check if directory has content (not empty)
        if [ "$(ls -A "$full_path" 2>/dev/null)" ]; then
            log_info "Repository already exists with content: $full_path"
            return 0
        else
            log_info "Repository directory exists but is empty, removing and cloning: $full_path"
            sudo -u "$USER_NAME" rmdir "$full_path"
        fi
    fi
    
    log_info "Cloning repository: $repo_url -> $full_path"
    log_info "Target directory: $target_dir"
    log_info "Repository name: $repo_name"
    
    # Clone repository as user - let git create the directory with the repo name
    log_info "Executing: cd '$target_dir' && git clone '$repo_url'"
    if sudo -u "$USER_NAME" bash -c "cd '$target_dir' && git clone '$repo_url'"; then
        log_success "Repository cloned successfully: $repo_name"
        
        # Verify the clone actually created the directory with content
        if [ -d "$full_path" ] && [ "$(ls -A "$full_path" 2>/dev/null)" ]; then
            log_info "Verifying cloned repository has content: $full_path"
            # Now set permissions on the directory that git created
            setup_directory_permissions "$full_path"
            return 0
        else
            log_error "Git clone completed but directory is missing or empty: $full_path"
            log_error "This indicates the git clone may have failed silently"
            exit 1
        fi
    else
        log_error "Error cloning repository: $repo_url into $target_dir"
        log_error "Git clone command failed"
        exit 1
    fi
}

# Function to ensure git is available
ensure_git_available() {
    log_step "Checking Git availability..."
    
    if command -v git >/dev/null 2>&1; then
        log_success "Git is already installed"
        return 0
    fi
    
    log_info "Git not found, installing..."
    if pacman -S --noconfirm git; then
        log_success "Git installed successfully"
    else
        log_error "Failed to install Git"
        exit 1
    fi
}

setup_git_repositories() {
    log_step "Setting up Git repositories..."
    
    # Define repositories to clone (URL|target_directory|custom_name)
    # Now target_directory is where we want to clone INTO (not the final directory name)
    local repositories=(
        "https://github.com/cpalau/arch-linux-dotfiles.git|$USER_HOME/development/projects/dotfiles|"
    )
    
    # Clone repositories
    local cloned_repos=()
    for repo_info in "${repositories[@]}"; do
        IFS='|' read -r repo_url target_dir custom_name <<< "$repo_info"
        
        # Clone repository (this will exit on failure due to set -e and exit 1 in function)
        clone_git_repository "$repo_url" "$target_dir" "$custom_name"
        
        # If we get here, the clone was successful
        local repo_name="${custom_name:-$(basename "$repo_url" .git)}"
        cloned_repos+=("$target_dir/$repo_name")
    done
    
    # Log cloned repositories
    if [ ${#cloned_repos[@]} -gt 0 ]; then
        log_success "Git repositories setup completed"
        for repo_path in "${cloned_repos[@]}"; do
            log_info "✓ $repo_path"
        done
    else
        log_error "No repositories were cloned successfully"
        exit 1
    fi
}

# Function to create initial system backup using Timeshift with rsync
create_initial_timeshift_backup() {
    log_step "Creating initial system backup with Timeshift (rsync mode)..."
    
    local BACKUP_DEVICE="/dev/sda1"
    local BACKUP_MOUNT_POINT="/mnt/backup"
    local BACKUP_DIR="$BACKUP_MOUNT_POINT/backups"
    
    # Check if timeshift is available
    if ! command -v timeshift >/dev/null 2>&1; then
        log_error "Timeshift not found. Installing..."
        if ! pacman -S --noconfirm timeshift; then
            log_error "Failed to install Timeshift"
            log_info "Continuing without initial backup"
            return 1
        fi
    fi
    
    # Check if backup device exists
    if [ ! -b "$BACKUP_DEVICE" ]; then
        log_error "Backup device $BACKUP_DEVICE not found"
        log_info "Skipping initial backup - device not available"
        return 1
    fi
    
    # Create mount point and mount device
    mkdir -p "$BACKUP_MOUNT_POINT"
    log_info "Mounting backup device $BACKUP_DEVICE to $BACKUP_MOUNT_POINT"
    if ! mount "$BACKUP_DEVICE" "$BACKUP_MOUNT_POINT" 2>/dev/null; then
        log_error "Failed to mount backup device"
        log_info "Skipping initial backup - mount failed"
        return 1
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Configure Timeshift for rsync mode with custom location
    log_info "Configuring Timeshift for rsync mode..."
    log_info "Backup location: $BACKUP_DIR"
    
    # Set Timeshift to use rsync mode and specify backup location
    timeshift --rsync \
              --snapshot-device "$BACKUP_DEVICE" \
              --backup-device "$BACKUP_DEVICE"
    
    # Create the initial backup
    log_info "Starting Timeshift backup..."
    log_info "This process may take 15-30 minutes depending on system size"
    log_info "Please be patient while the initial backup completes..."
    
    if timeshift --create --comments "Initial post-install backup" --tags D; then
        log_success "Initial Timeshift backup created successfully"
        
        # Show backup info
        log_info "Backup completed. Listing recent snapshots:"
        timeshift --list || log_info "Unable to list snapshots"
        
        # Show backup size if possible
        if [ -d "$BACKUP_DIR/timeshift" ]; then
            local backup_size=$(du -sh "$BACKUP_DIR/timeshift" 2>/dev/null | cut -f1)
            log_info "Backup size: $backup_size"
        fi
        
    else
        log_error "Timeshift backup failed"
        log_info "Continuing with post-installation setup..."
    fi
    
    log_success "Timeshift backup process completed"
    log_info "Backup device remains mounted at $BACKUP_MOUNT_POINT for future use"
}

log_step "Starting Arch Linux post-installation setup..."

# Create initial system backup as first step
create_initial_timeshift_backup

# Create directory structures
create_development_structure

# Ensure Git is available before cloning repositories
ensure_git_available

# Setup Git repositories
setup_git_repositories

log_success "Post-installation setup completed!"
log_info "Tasks completed:"
log_info "  ✓ Initial system backup created with Timeshift"
log_info "  ✓ Directory structure created:"
log_info "    • /home/cristian/development/"
log_info "    • /home/cristian/development/projects/"
log_info "    • /home/cristian/development/projects/dotfiles/"
log_info "  ✓ Git repositories cloned:"
log_info "    • arch-linux-dotfiles (/home/cristian/development/projects/dotfiles/arch-linux-dotfiles/)"
log_info ""
log_info "System backup location: /dev/sda1/backups (if backup was successful)"
log_info "Use 'timeshift --list' to view available snapshots"