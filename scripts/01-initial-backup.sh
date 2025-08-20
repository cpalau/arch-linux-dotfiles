#!/bin/bash

# Initial system backup script for Arch Linux
# Creates first backup using Timeshift with rsync backend
# Created by: Cristian Palau

set -e  # Exit on any error

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/logging.sh"
source "$SCRIPT_DIR/utils/helpers.sh"

# Function to ensure Timeshift is available
ensure_timeshift_available() {
    log_step "Checking Timeshift availability..."
    
    if command -v timeshift >/dev/null 2>&1; then
        log_success "Timeshift is already installed"
        return 0
    fi
    
    log_info "Timeshift not found, installing..."
    if pacman -S --noconfirm timeshift; then
        log_success "Timeshift installed successfully"
    else
        log_error "Failed to install Timeshift"
        exit 1
    fi
}

# Function to create initial system backup using Timeshift with rsync
create_initial_timeshift_backup() {
    log_step "Creating initial system backup with Timeshift (rsync mode)..."
    
    local BACKUP_DEVICE="/dev/sda1"
    local BACKUP_MOUNT_POINT="/mnt/backup"
    local BACKUP_DIR="$BACKUP_MOUNT_POINT/backups"
    
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
        log_info "Continuing with system setup..."
    fi
    
    log_success "Timeshift backup process completed"
    log_info "Backup device remains mounted at $BACKUP_MOUNT_POINT for future use"
}

# Main execution
log_step "Starting initial system backup process..."

# Ensure Timeshift is available before creating backup
ensure_timeshift_available

# Create initial system backup
create_initial_timeshift_backup

log_success "Initial backup process completed!"
log_info "Backup location: /dev/sda1/backups (if backup was successful)"
log_info "Use 'timeshift --list' to view available snapshots"