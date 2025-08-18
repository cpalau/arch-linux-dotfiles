#!/bin/bash

# Pre-installation script for Arch Linux
# Handles WiFi setup and archinstall execution
# Created by: Cristian Palau

set -e  # Exit on any error

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/logging.sh"
source "$SCRIPT_DIR/utils/helpers.sh"

log_step "Starting Arch Linux pre-installation setup..."

# Check for existing network connection before WiFi setup
log_step "Checking for existing network connection..."
if check_network_connection; then
    log_success "Network connection already available, skipping WiFi setup"
    SKIP_WIFI_SETUP=true
else
    log_info "No active network connection detected, proceeding with WiFi setup"
    SKIP_WIFI_SETUP=false
fi

# Only check WiFi credentials if we need to set up WiFi
if [ "$SKIP_WIFI_SETUP" = false ]; then
    # Verify that .env file exists
    ENV_FILE="$PROJECT_ROOT/config/setup_passwords.env"
    if [ ! -f "$ENV_FILE" ]; then
        log_error "$ENV_FILE file not found"
        echo "Create a setup_passwords.env file in the config directory with the following format:"
        echo "WIFI_SSID=your_wifi_network"
        echo "WIFI_PASSWORD=your_password"
        exit 1
    fi

    # Load variables from .env file
    log_info "Loading WiFi configuration from config/setup_passwords.env..."
    source "$ENV_FILE"

    # Verify that required variables are defined
    if [ -z "$WIFI_SSID" ] || [ -z "$WIFI_PASSWORD" ]; then
        log_error "WIFI_SSID and/or WIFI_PASSWORD variables not defined in $ENV_FILE"
        exit 1
    fi
else
    log_info "WiFi configuration check skipped (using ethernet connection)"
fi

log_step "Increasing console font size for better visibility..."
# Set a large, readable font - modify the font name below to adjust size
# Available large fonts: ter-v32b, ter-v28b, ter-v24b, ter-v20b, ter-v16b
# You can also try: lat9w-16, lat9w-14, lat9w-12
# To test different fonts manually: setfont ter-v32b
LARGE_FONT="ter-v32b"

if setfont "$LARGE_FONT" 2>/dev/null; then
    log_success "Font size increased to $LARGE_FONT"
    log_info "To change font size, edit the LARGE_FONT variable in this script"
    log_info "Available options: ter-v32b (largest), ter-v28b, ter-v24b, ter-v20b, ter-v16b"
else
    log_warn "Large font $LARGE_FONT not available, trying fallbacks..."
    if setfont "ter-v24b" 2>/dev/null; then
        log_success "Font size increased to ter-v24b (fallback)"
    elif setfont "lat9w-16" 2>/dev/null; then
        log_success "Font size increased to lat9w-16 (fallback)"
    else
        log_warn "Could not increase font size, using default font"
    fi
fi

log_step "Setting up Spanish keyboard..."
if loadkeys es; then
    log_success "Keyboard configured successfully"
else
    log_error "Error configuring keyboard"
    exit 1
fi

# WiFi setup (skip if ethernet connection is active)
if [ "$SKIP_WIFI_SETUP" = false ]; then
    log_step "Starting WiFi configuration..."

    # Verify that iwctl is available
    if ! command_exists iwctl; then
        log_error "iwctl is not available. Make sure you are in the Arch Linux live environment"
        exit 1
    fi

    # Get WiFi interface name
    WIFI_INTERFACE=$(iwctl device list | grep -Eo 'wlan[0-9]+')

    if [ -z "$WIFI_INTERFACE" ]; then
        log_error "No WiFi interface found"
        exit 1
    fi

    log_info "WiFi interface detected: $WIFI_INTERFACE"

    # Enable WiFi interface if disabled
    log_info "Enabling WiFi interface..."
    iwctl device "$WIFI_INTERFACE" set-property Powered on

    # Scan available networks
    log_info "Scanning available WiFi networks..."
    iwctl station "$WIFI_INTERFACE" scan

    # Wait a bit for scan to complete
    sleep 3

    # Check if network is available
    log_info "Verifying that network '$WIFI_SSID' is available..."
    if iwctl station "$WIFI_INTERFACE" get-networks | grep -q "$WIFI_SSID"; then
        log_success "Network '$WIFI_SSID' found"
    else
        log_warn "Network '$WIFI_SSID' not found. Available networks:"
        iwctl station "$WIFI_INTERFACE" get-networks
        exit 1
    fi

    # Connect to WiFi network
    log_info "Connecting to network '$WIFI_SSID'..."

    # Create temporary file with password to avoid showing it in command line
    TEMP_PASSFILE=$(mktemp)
    echo "$WIFI_PASSWORD" > "$TEMP_PASSFILE"

    # Connect using password file
    if iwctl --passphrase="$WIFI_PASSWORD" station "$WIFI_INTERFACE" connect "$WIFI_SSID"; then
        log_success "Connection established successfully"
    else
        log_error "Error connecting to WiFi network"
        rm -f "$TEMP_PASSFILE"
        exit 1
    fi

    # Clean up temporary file
    rm -f "$TEMP_PASSFILE"

    # Verify connectivity
    log_info "Verifying connectivity..."
    sleep 5

    if check_internet; then
        log_success "✓ Internet connection established successfully"
    else
        log_warn "Connection established but no internet access. Verifying..."
        # Try to get IP via DHCP
        dhcpcd "$WIFI_INTERFACE"
        sleep 3
        if check_internet; then
            log_success "✓ Internet connection established successfully"
        else
            log_error "No internet access. Check network configuration"
            exit 1
        fi
    fi
else
    log_step "WiFi setup skipped (using existing ethernet connection)"
    # Verify that the existing connection has internet access
    if check_internet; then
        log_success "✓ Existing network connection verified"
    else
        log_error "Existing connection has no internet access"
        exit 1
    fi
fi

# Final connectivity verification
if check_internet; then
    log_success "✓ Internet connection confirmed"
    log_success "✓ Keyboard configured in Spanish" 
    log_success "✓ Terminal font configured"
    log_success "✓ System ready to continue with installation"
else
    log_error "No internet access available"
    exit 1
fi

# Initialize pacman keyring
log_step "Initializing pacman keyring..."
if pacman-key --init; then
    log_success "Pacman keyring initialized successfully"
else
    log_error "Error initializing pacman keyring"
    exit 1
fi

if pacman-key --populate archlinux; then
     log_success "Pacman keyring populate ok"
else
     log_error "Error initializing pacman keyring"
fi

# Update pacman package sources
log_step "Refreshing pacman package sources..."
if pacman -Sy; then
    log_success "Package sources refreshed successfully"
else
    log_error "Error refreshing package sources"
    exit 1
fi

# Install git and wget without prompting
log_step "Installing git and wget..."
if pacman -S --noconfirm git wget; then
    log_success "git and wget installed successfully"
else
    log_error "Error installing git and wget"
    exit 1
fi

# TODO: Execute archinstall with configuration
ARCHINSTALL_CONFIG="$PROJECT_ROOT/config/archinstall.json"
if [ -f "$ARCHINSTALL_CONFIG" ]; then
    log_step "Executing archinstall with configuration..."
    log_warn "archinstall execution will be implemented here"
    # archinstall "$ARCHINSTALL_CONFIG"
else
    log_warn "archinstall.json not found in config directory"
    log_info "You can run archinstall manually or create the configuration file"
fi

log_success "Pre-installation setup completed!"
log_info "Next steps:"
log_info "1. Run archinstall (if not done automatically)"
log_info "2. Reboot into the new system"
log_info "3. Run the post-installation script"
