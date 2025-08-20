#!/bin/bash
# 03-dotfiles.sh - Deploy dotfiles using GNU Stow
# Part of Arch Linux dotfiles configuration system

# Source utility functions
source "$(dirname "$0")/utils/colors.sh"
source "$(dirname "$0")/utils/logging.sh"
source "$(dirname "$0")/utils/helpers.sh"

# Configuration
PROJECT_ROOT="/home/cristian/development/projects/dotfiles"
DOTFILES_DIR="$PROJECT_ROOT/dotfiles"
HOME_DIR="/home/cristian"

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
    
    log_success "✅ Prerequisites verified"
}

deploy_dotfiles() {
    log_info "Starting dotfiles deployment with GNU Stow..."
    
    # Navigate to project root directory
    cd "$PROJECT_ROOT" || {
        log_error "Failed to navigate to project directory: $PROJECT_ROOT"
        exit 1
    }
    
    # Remove existing conflicting files
    remove_existing_files
    
    # Use stow to create symlinks for all dotfiles
    log_info "Deploying dotfiles with GNU Stow..."
    log_info "Source: $DOTFILES_DIR"
    log_info "Target: $HOME_DIR"
    
    if stow --verbose --target="$HOME_DIR" dotfiles; then
        log_success "✅ Dotfiles deployed successfully!"
        
        # Set proper permissions for sensitive files
        set_file_permissions
        
        # Reload configurations
        reload_configurations
        
    else
        log_error "❌ Failed to deploy dotfiles with GNU Stow"
        exit 1
    fi
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
    
    local files=(
        ".bashrc"
        ".gitconfig"
        ".sshd_config"
        ".gnupg/gpg.conf"
        ".gnupg/gpg-agent.conf"
    )
    
    local success_count=0
    local total_count=${#files[@]}
    
    for file in "${files[@]}"; do
        if [[ -L "$HOME_DIR/$file" ]]; then
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
    log_info "You may need to restart your terminal to see all changes"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi