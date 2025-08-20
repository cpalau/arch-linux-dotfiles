#!/bin/bash
# 04-services.sh - Configure and enable system services
# Part of Arch Linux dotfiles configuration system

# Source utility functions
source "$(dirname "$0")/utils/colors.sh"
source "$(dirname "$0")/utils/logging.sh" 
source "$(dirname "$0")/utils/helpers.sh"

configure_docker() {
    log_info "Configuring Docker service..."
    
    # Start and enable Docker service
    if sudo systemctl start docker.service; then
        log_success "✅ Docker service started"
    else
        log_error "❌ Failed to start Docker service"
        return 1
    fi
    
    if sudo systemctl enable docker.service; then
        log_success "✅ Docker service enabled"
    else
        log_error "❌ Failed to enable Docker service"
        return 1
    fi
    
    # Add user to docker group
    if sudo usermod -aG docker $USER; then
        log_success "✅ User added to docker group"
        
        # Apply group changes
        if newgrp docker; then
            log_success "✅ Docker group activated"
        else
            log_warning "⚠️  Docker group changes will take effect after logout/login"
        fi
    else
        log_error "❌ Failed to add user to docker group"
        return 1
    fi
}

configure_ssh() {
    log_info "Configuring SSH service..."
    
    # Start and enable SSH service
    if sudo systemctl start sshd.service; then
        log_success "✅ SSH service started"
    else
        log_error "❌ Failed to start SSH service"
        return 1
    fi
    
    if sudo systemctl enable sshd.service; then
        log_success "✅ SSH service enabled"
    else
        log_error "❌ Failed to enable SSH service"
        return 1
    fi
}

configure_cups() {
    log_info "Configuring CUPS printing service..."
    
    # Start and enable CUPS service
    if sudo systemctl start cups.service; then
        log_success "✅ CUPS service started"
    else
        log_error "❌ Failed to start CUPS service"
        return 1
    fi
    
    if sudo systemctl enable cups.service; then
        log_success "✅ CUPS service enabled"
    else
        log_error "❌ Failed to enable CUPS service"
        return 1
    fi
}

verify_services() {
    log_info "Verifying service status..."
    
    local services=("docker" "sshd" "cups")
    local success_count=0
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet ${service}.service; then
            log_success "✅ $service is running"
            ((success_count++))
        else
            log_warning "⚠️  $service is not running"
        fi
    done
    
    log_info "Services verification: $success_count/${#services[@]} services running"
}

main() {
    print_banner "System Services Configuration"
    
    log_info "This script will configure and enable system services:"
    log_info "- Docker: Container platform"
    log_info "- SSH: Secure Shell daemon"
    log_info "- CUPS: Printing system"
    
    if ! confirm_action "Configure system services?"; then
        log_info "Services configuration cancelled"
        exit 0
    fi
    
    # Configure services
    configure_docker
    configure_ssh
    configure_cups
    
    # Verify all services are running
    verify_services
    
    log_success "🎉 System services configured successfully!"
    log_info "Note: You may need to logout/login for Docker group changes to take effect"
    log_info "SSH is now available on port 2222 (as configured in .sshd_config)"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi