#!/bin/bash
# 03-dotfiles.sh - Deploy dotfiles using GNU Stow
# Part of Arch Linux dotfiles configuration system

# Source utility functions
source "$(dirname "$0")/utils/colors.sh"
source "$(dirname "$0")/utils/logging.sh"
source "$(dirname "$0")/utils/helpers.sh"

# Configuration
PROJECT_ROOT="/home/cristian/development/projects/arch-linux-dotfiles"
DOTFILES_DIR="$PROJECT_ROOT/dotfiles"
HOME_DIR="/home/cristian"
SYSTEM_BACKUP_DIR="/tmp/dotfiles-system-backup-$(date +%Y%m%d-%H%M%S)"

remove_existing_files() {
    log_info "Removing existing dotfiles that conflict with stow..."
    
    local files=(
        ".bashrc"
        ".gitconfig" 
        ".sshd_config"
        ".gnupg"
    )
    
    for file in "${files[@]}"; do
        if [[ -e "$HOME_DIR/$file" ]] && [[ ! -L "$HOME_DIR/$file" ]]; then
            log_info "Removing existing $file"
            rm -rf "$HOME_DIR/$file"
        fi
    done
}

remove_system_conflicts() {
    log_info "Removing existing system files that conflict with stow..."
    
    local system_files=(
        "/etc/timeshift/timeshift.json"
    )
    
    for file in "${system_files[@]}"; do
        if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
            log_info "Backing up and removing existing system file: $file"
            
            # Create backup directory if it doesn't exist
            sudo mkdir -p "$SYSTEM_BACKUP_DIR$(dirname "$file")"
            
            # Backup the file
            sudo cp "$file" "$SYSTEM_BACKUP_DIR$file" 2>/dev/null || true
            
            # Remove the original file
            sudo rm -rf "$file"
        fi
    done
}

backup_system_files() {
    log_info "Creating backup directory for system files: $SYSTEM_BACKUP_DIR"
    sudo mkdir -p "$SYSTEM_BACKUP_DIR"
    
    local system_files=(
        "/etc/timeshift/timeshift.json"
    )
    
    for file in "${system_files[@]}"; do
        if [[ -e "$file" ]]; then
            log_info "Backing up system file: $file"
            sudo mkdir -p "$SYSTEM_BACKUP_DIR$(dirname "$file")"
            sudo cp "$file" "$SYSTEM_BACKUP_DIR$file" 2>/dev/null || true
        fi
    done
}

verify_prerequisites() {
    log_info "Verifying prerequisites..."
    
    # Verify stow is installed
    if ! command -v stow &> /dev/null; then
        log_error "GNU Stow is not installed. Please install it first:"
        log_info "sudo pacman -S stow"
        exit 1
    fi
    
    # Verify dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    
    # Verify project root exists
    if [[ ! -d "$PROJECT_ROOT" ]]; then
        log_error "Project root directory not found: $PROJECT_ROOT"
        exit 1
    fi
    
    # Verify we can use sudo for system files
    if ! sudo -n true 2>/dev/null; then
        log_warning "⚠️  Script requires sudo privileges for system files"
        log_info "Please run with sudo or ensure passwordless sudo is configured"
        if ! confirm_action "Continue without system file deployment?"; then
            exit 1
        fi
    fi
    
    log_success "✅ Prerequisites verified"
}

deploy_user_dotfiles() {
    log_info "Deploying user dotfiles with GNU Stow..."
    
    # Navigate to project root directory
    cd "$PROJECT_ROOT" || {
        log_error "Failed to navigate to project directory: $PROJECT_ROOT"
        exit 1
    }
    
    # Remove existing conflicting files
    remove_existing_files
    
    # Use stow to create symlinks for user dotfiles (exclude etc directory)
    log_info "Source: $DOTFILES_DIR"
    log_info "Target: $HOME_DIR"
    
    if stow --verbose --target="$HOME_DIR" --ignore="etc" dotfiles; then
        log_success "✅ User dotfiles deployed successfully!"
    else
        log_error "❌ Failed to deploy user dotfiles with GNU Stow"
        exit 1
    fi
}

deploy_system_dotfiles() {
    log_info "Deploying system dotfiles with GNU Stow..."
    
    # Check if etc directory exists
    if [[ ! -d "$DOTFILES_DIR/etc" ]]; then
        log_info "No system dotfiles found (etc directory doesn't exist)"
        return 0
    fi
    
    # Check if we have sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_warning "⚠️  Skipping system dotfiles deployment (no sudo privileges)"
        return 0
    fi
    
    # Navigate to dotfiles directory
    cd "$DOTFILES_DIR" || {
        log_error "Failed to navigate to dotfiles directory: $DOTFILES_DIR"
        exit 1
    }
    
    # Backup existing system files
    backup_system_files
    
    # Remove conflicting system files
    remove_system_conflicts
    
    # Use stow to create symlinks for system files
    log_info "Deploying system files to /etc"
    
    if sudo stow --verbose --target="/etc" etc; then
        log_success "✅ System dotfiles deployed successfully!"
        
        # Set proper permissions for system files
        set_system_file_permissions
        
    else
        log_error "❌ Failed to deploy system dotfiles with GNU Stow"
        log_info "System backup created at: $SYSTEM_BACKUP_DIR"
        exit 1
    fi
}

deploy_dotfiles() {
    log_info "Starting comprehensive dotfiles deployment..."
    
    # Deploy user dotfiles
    deploy_user_dotfiles
    
    # Deploy system dotfiles
    deploy_system_dotfiles
    
    # Set permissions and reload configurations
    set_file_permissions
    reload_configurations
}

set_file_permissions() {
    log_info "Setting proper file permissions..."
    
    # GnuPG directory permissions
    if [[ -d "$HOME_DIR/.gnupg" ]]; then
        chmod 700 "$HOME_DIR/.gnupg"
        if [[ -f "$HOME_DIR/.gnupg/gpg.conf" ]]; then
            chmod 600 "$HOME_DIR/.gnupg/gpg.conf"
        fi
        if [[ -f "$HOME_DIR/.gnupg/gpg-agent.conf" ]]; then
            chmod 600 "$HOME_DIR/.gnupg/gpg-agent.conf"
        fi
        log_success "✅ GnuPG permissions set"
    fi
    
    # SSH config permissions
    if [[ -f "$HOME_DIR/.sshd_config" ]]; then
        chmod 644 "$HOME_DIR/.sshd_config"
        log_success "✅ SSH config permissions set"
    fi
    
    # Bashrc permissions
    if [[ -f "$HOME_DIR/.bashrc" ]]; then
        chmod 644 "$HOME_DIR/.bashrc"
        log_success "✅ Bashrc permissions set"
    fi
    
    # Git config permissions
    if [[ -f "$HOME_DIR/.gitconfig" ]]; then
        chmod 644 "$HOME_DIR/.gitconfig"
        log_success "✅ Git config permissions set"
    fi
}

set_system_file_permissions() {
    log_info "Setting proper system file permissions..."
    
    # Timeshift config permissions
    if [[ -f "/etc/timeshift/timeshift.json" ]]; then
        sudo chmod 644 "/etc/timeshift/timeshift.json"
        sudo chown root:root "/etc/timeshift/timeshift.json"
        log_success "✅ Timeshift config permissions set"
    fi
    
    # Set proper ownership for /etc/timeshift directory
    if [[ -d "/etc/timeshift" ]]; then
        sudo chown -R root:root "/etc/timeshift"
        sudo chmod 755 "/etc/timeshift"
        log_success "✅ Timeshift directory permissions set"
    fi
}

reload_configurations() {
    log_info "Reloading configurations..."
    
    # Reload bashrc if it exists and we're in bash
    if [[ -f "$HOME_DIR/.bashrc" ]] && [[ -n "$BASH_VERSION" ]]; then
        source "$HOME_DIR/.bashrc"
        log_success "✅ Bash configuration reloaded"
    fi
    
    # Restart GPG agent if GnuPG config exists
    if [[ -d "$HOME_DIR/.gnupg" ]]; then
        gpgconf --kill gpg-agent 2>/dev/null || true
        gpg-agent --daemon 2>/dev/null || true
        log_success "✅ GPG agent restarted"
    fi
}

verify_deployment() {
    log_info "Verifying dotfiles deployment..."
    
    local user_files=(
        ".bashrc"
        ".gitconfig"
        ".sshd_config"
        ".gnupg/gpg.conf"
        ".gnupg/gpg-agent.conf"
    )
    
    local system_files=(
        "/etc/timeshift/timeshift.json"
    )
    
    local success_count=0
    local total_count=$((${#user_files[@]} + ${#system_files[@]}))
    
    # Check user files
    for file in "${user_files[@]}"; do
        if [[ -L "$HOME_DIR/$file" ]]; then
            log_success "✅ $file → symlinked correctly"
            ((success_count++))
        else
            log_warning "⚠️  $file → not found or not symlinked"
        fi
    done
    
    # Check system files
    for file in "${system_files[@]}"; do
        if [[ -L "$file" ]]; then
            log_success "✅ $file → symlinked correctly"
            ((success_count++))
        else
            log_warning "⚠️  $file → not found or not symlinked"
        fi
    done
    
    log_info "Deployment verification: $success_count/$total_count files deployed"
    
    if [[ $success_count -eq $total_count ]]; then
        log_success "🎉 All dotfiles deployed successfully!"
    else
        log_warning "⚠️  Some dotfiles may not have been deployed correctly"
    fi
}

main() {
    print_banner "Dotfiles Deployment"
    
    log_info "Project root: $PROJECT_ROOT"
    log_info "Dotfiles directory: $DOTFILES_DIR"
    log_info "Home directory: $HOME_DIR"
    log_info "System backup directory: $SYSTEM_BACKUP_DIR"
    
    log_info "This script will deploy:"
    log_info "- User dotfiles (home directory)"
    log_info "- System dotfiles (requires sudo for /etc)"
    
    # Confirmation prompt
    if ! confirm_action "Deploy dotfiles using GNU Stow?"; then
        log_info "Dotfiles deployment cancelled"
        exit 0
    fi
    
    # Execute deployment steps
    verify_prerequisites
    deploy_dotfiles
    verify_deployment
    
    log_success "🎉 Dotfiles deployment completed successfully!"
    log_info "All configuration files are now symlinked and active"
    if [[ -d "$SYSTEM_BACKUP_DIR" ]]; then
        log_info "System backup created at: $SYSTEM_BACKUP_DIR"
    fi
    log_info "You may need to restart your terminal to see all changes"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi