#!/bin/bash

source "$(dirname "$0")/utils/colors.sh"
source "$(dirname "$0")/utils/logging.sh"
source "$(dirname "$0")/utils/helpers.sh"

print_header "Activating Services"

print_info "Enabling and starting OpenSSH service..."
if sudo systemctl enable sshd && sudo systemctl start sshd; then
    print_success "OpenSSH service enabled and started"
else
    print_error "Failed to enable OpenSSH service"
    exit 1
fi

print_success "All services configured successfully!"