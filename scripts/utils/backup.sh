#!/bin/bash

# Automated system backup utility for Arch Linux
# Creates timestamped backups using Timeshift with rsync backend
# Can be used for initial backup or scheduled backups
# Created by: Cristian Palau

set -e  # Exit on any error

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source utilities
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/helpers.sh"

# Global backup configuration
BACKUP_DEVICE="/dev/sda1"
BACKUP_MOUNT_POINT="/mnt/backup"
BACKUP_DIR="$BACKUP_MOUNT_POINT/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

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

# Function to create timestamped system backup using Timeshift with rsync
create_timeshift_backup() {
    local backup_type="${1:-automatic}"
    local backup_comment="${2:-Automated system backup}"
    
    log_step "Creating system backup with Timeshift (rsync mode)..."
    
    # Check if backup device exists
    if [ ! -b "$BACKUP_DEVICE" ]; then
        log_error "Backup device $BACKUP_DEVICE not found"
        log_info "Skipping backup - device not available"
        return 1
    fi
    
    # Create mount point and mount device if not already mounted
    mkdir -p "$BACKUP_MOUNT_POINT"
    if ! mountpoint -q "$BACKUP_MOUNT_POINT"; then
        log_info "Mounting backup device $BACKUP_DEVICE to $BACKUP_MOUNT_POINT"
        if ! mount "$BACKUP_DEVICE" "$BACKUP_MOUNT_POINT" 2>/dev/null; then
            log_error "Failed to mount backup device"
            log_info "Skipping backup - mount failed"
            return 1
        fi
    else
        log_info "Backup device already mounted at $BACKUP_MOUNT_POINT"
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Configure Timeshift for rsync mode with custom location
    log_info "Configuring Timeshift for rsync mode..."
    log_info "Backup location: $BACKUP_DIR"
    log_info "Backup timestamp: $TIMESTAMP"
    
    # Set Timeshift to use rsync mode and specify backup location
    timeshift --rsync \
              --snapshot-device "$BACKUP_DEVICE" \
              --backup-device "$BACKUP_DEVICE"
    
    # Create the timestamped backup
    log_info "Starting Timeshift backup..."
    log_info "Backup type: $backup_type"
    log_info "This process may take 15-30 minutes depending on system size"
    log_info "Please be patient while the backup completes..."
    
    # Create backup with timestamp in comment
    local full_comment="$backup_comment - $TIMESTAMP"
    if timeshift --create --comments "$full_comment" --tags D; then
        log_success "Timeshift backup created successfully"
        
        # Show backup info
        log_info "Backup completed. Listing recent snapshots:"
        timeshift --list || log_info "Unable to list snapshots"
        
        # Show backup size if possible
        if [ -d "$BACKUP_DIR/timeshift" ]; then
            local backup_size=$(du -sh "$BACKUP_DIR/timeshift" 2>/dev/null | cut -f1)
            log_info "Total backup size: $backup_size"
        fi
        
    else
        log_error "Timeshift backup failed"
        log_info "Continuing with system operations..."
    fi
    
    log_success "Timeshift backup process completed"
    log_info "Backup device remains mounted at $BACKUP_MOUNT_POINT for future use"
}

# Function to show usage information
show_usage() {
    echo "Usage: $0 [type] [comment]"
    echo ""
    echo "Parameters:"
    echo "  type     - Backup type (default: automatic)"
    echo "             Options: initial, scheduled, manual, automatic"
    echo "  comment  - Custom backup comment (optional)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Create automatic backup"
    echo "  $0 initial                           # Create initial backup"
    echo "  $0 manual \"Before system update\"     # Create manual backup with comment"
    echo "  $0 scheduled                         # Create scheduled backup"
    echo ""
    echo "The script will:"
    echo "  - Install Timeshift if not available"
    echo "  - Mount backup device ($BACKUP_DEVICE) if not mounted"
    echo "  - Create timestamped backup with rsync backend"
    echo "  - Store backup in $BACKUP_DIR/"
    echo ""
}

# Check for help argument
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_usage
    exit 0
fi

# Main execution
log_step "Starting system backup process..."

# Get parameters
BACKUP_TYPE="${1:-automatic}"
BACKUP_COMMENT="${2:-Automated system backup}"

log_info "Backup type: $BACKUP_TYPE"
log_info "Backup comment: $BACKUP_COMMENT"

# Ensure Timeshift is available before creating backup
ensure_timeshift_available

# Create timestamped system backup
create_timeshift_backup "$BACKUP_TYPE" "$BACKUP_COMMENT"

log_success "Backup process completed!"
log_info "Backup location: $BACKUP_DIR (if backup was successful)"
log_info "Use 'timeshift --list' to view available snapshots"