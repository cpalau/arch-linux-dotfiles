# Arch Linux Dotfiles Setup

My comprehensive, modular setup system for Arch Linux installation and configuration management.

## 🚀 Features

- **Automated Network Detection**: I've created smart network detection that automatically uses ethernet when available
- **Automated WiFi Setup**: I've created scripts that connect to WiFi networks using configuration files  
- **Archinstall Integration**: I use JSON configuration for consistent installations
- **Modular Architecture**: I've designed separate scripts for different setup phases
- **Dotfiles Management**: I've built automated deployment of configuration files
- **Package Management**: I've organized installation of essential and optional packages
- **Service Configuration**: I've automated setup of system services

## 📁 Project Structure

```
arch-linux/
├── setup                           # My main entry point script
├── config/
│   ├── setup_passwords.env        # WiFi credentials (required only for WiFi setup)
│   ├── archinstall_config.json    # Archinstall system configuration ✅
│   └── archinstall_credentials.json # Archinstall user credentials ✅
├── scripts/
│   ├── 00-pre-install.sh          # Network detection + WiFi/ethernet setup + archinstall execution ✅
│   ├── 01-initial-backup.sh       # Initial system backup using Timeshift ✅
│   ├── 02-post-install.sh         # Post-installation configuration ✅
│   ├── 03-packages.sh             # Package installation ✅
│   ├── 04-dotfiles.sh             # Dotfiles deployment using GNU Stow ✅
│   ├── 05-services.sh             # System services configuration (Docker, SSH, CUPS) ✅
│   └── utils/
│       ├── colors.sh              # My color definitions ✅
│       ├── logging.sh             # My logging functions ✅
│       └── helpers.sh             # My common helper functions ✅
├── dotfiles/
│   ├── .bashrc                    # Bash shell configuration with environment variables ✅
│   ├── .vimrc                     # My vim configuration (to be created)
│   ├── .gitconfig                 # My git configuration ✅
│   ├── .sshd_config               # SSH server configuration ✅
│   ├── .gnupg/                    # GnuPG configuration directory ✅
│   │   ├── gpg.conf               # GnuPG main configuration ✅
│   │   └── gpg-agent.conf         # GPG agent configuration ✅
│   ├── etc/                       # System configuration files (requires root) ✅
│   │   └── timeshift/
│   │       └── timeshift.json     # Timeshift backup configuration ✅
│   └── .config/                   # My application configurations (to be created)
├── private/                        # Sensitive files (NOT committed to git) ✅
│   ├── ssh/                       # SSH keys and configuration
│   ├── gpg/                       # PGP/GPG keys
│   ├── credentials/               # Other sensitive files
│   └── README.md                  # Documentation for private directory ✅
├── packages/
│   ├── pacman/
│   │   ├── base.txt               # Essential system packages (official repos) ✅
│   │   ├── development.txt        # Development tools (official repos) ✅
│   │   ├── desktop.txt            # Desktop environment (official repos) ✅
│   │   └── optional.txt           # Additional packages (official repos) ✅
│   └── aur/
│       ├── base.txt               # Essential packages from AUR ✅
│       ├── development.txt        # Development tools from AUR ✅
│       ├── desktop.txt            # Desktop applications from AUR ✅
│       └── optional.txt           # Optional AUR packages ✅
└── README.md                      # This documentation ✅
```

## 🛠️ Setup Process

### Phase 1: Pre-installation (From Arch Linux Live USB)

1. **Boot Arch Linux Live USB**

2. **Download dotfiles** (choose one option):

   **Option A: With Active Ethernet Connection**
   ```bash
   # Clone directly from GitHub repository
   git clone https://github.com/cpalau/arch-linux-dotfiles.git /root/arch-linux
   cd /root/arch-linux
   # Make setup script executable
   chmod +x setup
   ```

   **Option B: From USB Drive**
   ```bash
   # Mount your USB drive (replace sdX1 with your USB device)
   mount /dev/sdX1 /mnt
   # Copy the entire dotfiles directory
   cp -r /mnt/arch-linux /root/
   cd /root/arch-linux
   # Make setup script executable
   chmod +x setup
   ```
3. **Configure WiFi credentials** (skip if using ethernet):
   ```bash
   # Edit the existing configuration file
   echo "WIFI_SSID=your_network_name" > config/setup_passwords.env
   echo "WIFI_PASSWORD=your_password" >> config/setup_passwords.env
   ```
4. **Run my pre-installation setup** (handles WiFi connection and system preparation):
   ```bash
   ./setup pre-install
   ```

This will:
- **Automatically detect network connections** (ethernet takes priority over WiFi)
- Configure Spanish keyboard layout  
- Connect to WiFi network (only if ethernet is not available)
- Update package sources
- Install git and wget
- **Execute archinstall automatically** using provided configuration files
- **Complete system installation** with disk partitioning, user creation, and base setup

### Phase 2: Post-installation (From Installed System)

After rebooting into the new Arch Linux system:

```bash
./setup post-install
```

This will:
- **Create initial system backup** using Timeshift with rsync backend
- Configure my system settings
- Install my additional packages
- Deploy my dotfiles
- Setup my system services

### Full Setup (Complete Process)

For my complete automated setup:

```bash
./setup full
```

## 🌐 Network Connection Management

The setup script includes intelligent network detection that prioritizes ethernet connections:

### Automatic Network Detection
- **Ethernet Priority**: The script automatically detects active ethernet connections and verifies connectivity to archlinux.org
- **WiFi Fallback**: WiFi setup is only performed when ethernet is unavailable or cannot reach archlinux.org
- **Arch Linux Connectivity**: All connections are verified against archlinux.org to ensure package downloads will work

### Connection Types Supported
- **Ethernet**: Automatic detection of `eth*` and `en*` interfaces with active IP addresses
- **WiFi**: Manual configuration through `setup_passwords.env` file (used as fallback)

### How It Works
1. **Detection Phase**: Script scans for active ethernet interfaces with IP addresses
2. **Connectivity Test**: Tests connection to archlinux.org to ensure package repositories are accessible
3. **Priority Logic**: If ethernet passes connectivity test, WiFi setup is completely skipped
4. **Fallback Mode**: If ethernet fails or is unavailable, proceed with WiFi configuration
5. **Final Verification**: All connections are tested against archlinux.org before proceeding

## 💾 Initial System Backup

The system includes an automated backup solution using Timeshift with rsync backend:

### Backup Script (`scripts/01-initial-backup.sh`):

#### Features:
- **Timeshift Integration**: Uses Timeshift for professional system snapshots
- **Rsync Backend**: Efficient incremental backups using rsync
- **Custom Location**: Backups stored on `/dev/sda1/backups`
- **Automatic Mount**: Handles mounting and device verification
- **Error Handling**: Graceful fallback if backup device unavailable
- **Clean Installation**: Automatically installs Timeshift if not present

#### What It Does:
1. **Install Timeshift**: Ensures Timeshift is available via pacman
2. **Device Verification**: Checks if `/dev/sda1` backup device exists
3. **Mount Management**: Mounts backup device to `/mnt/backup`
4. **Configure Timeshift**: Sets up rsync mode with custom backup location
5. **Create Snapshot**: Creates initial system backup with timestamp
6. **Show Information**: Displays backup size and snapshot details
7. **Keep Device Mounted**: Leaves backup device mounted for future use

#### Usage:
```bash
# Run backup script directly
./scripts/01-initial-backup.sh

# Or as part of post-installation setup
./setup post-install
```

#### Backup Details:
- **Storage Location**: `/dev/sda1/backups/timeshift/`
- **Backup Type**: Complete system snapshot (excluding standard exclusions)
- **Format**: Timeshift snapshots with metadata
- **Incremental**: Future backups will be incremental for faster operation
- **Device Management**: Backup device remains mounted at `/mnt/backup`

#### Requirements:
- **Backup Device**: `/dev/sda1` must be available and mountable
- **Timeshift**: Automatically installed if not present
- **Disk Space**: Adequate space on backup device for system snapshot
- **Root Privileges**: Required for mounting and system backup

#### Backup Process:
The backup process typically takes 15-30 minutes depending on system size and creates a complete snapshot before any configuration changes are made, ensuring you can restore to a clean state if needed.

## ⚙️ Configuration Files

### WiFi Configuration (`config/setup_passwords.env`)

**Note**: This file is only required if you don't have an active ethernet connection. The script will automatically detect ethernet connections and skip WiFi setup when ethernet is available.

```bash
WIFI_SSID=your_network_name
WIFI_PASSWORD=your_password
```

### Archinstall Configuration

The system uses two separate files for archinstall automation:

#### System Configuration (`config/archinstall_config.json`)
Contains system-wide settings for the installation:
```json
{
    "bootloader": "Grub",
    "hostname": "pulgoso", 
    "kernels": ["linux-lts"],
    "locale_config": {
        "kb_layout": "es",
        "sys_lang": "es_ES.UTF-8"
    },
    "disk_config": {
        "config_type": "manual_partitioning",
        "device_modifications": [...]
    },
    "profile_config": {
        "profile": {"main": "Minimal"}
    }
}
```

#### User Credentials (`config/archinstall_credentials.json`)
Contains encrypted user passwords and configuration:
```json
{
    "root_enc_password": "$y$j9T$...",
    "users": [{
        "username": "cristian",
        "enc_password": "$y$j9T$...",
        "sudo": true,
        "groups": []
    }]
}
```

**Note**: Both files are included and ready to use. The credentials use encrypted passwords generated by archinstall.

## 🔐 Private Files Management

The `private/` directory is designed to store sensitive files that should NOT be committed to version control:

### Structure
```
private/
├── ssh/          # SSH keys and configuration
├── gpg/          # PGP/GPG keys  
├── credentials/  # Other sensitive files
└── README.md     # Documentation (this file IS committed)
```

### Usage
- Store SSH private/public keys in `private/ssh/`
- Store PGP/GPG keys in `private/gpg/`
- Store other sensitive files in `private/credentials/`
- The entire `private/` directory is ignored by git (except README.md)
- Use proper file permissions (600 for private keys)

### Security Notes
- Files in `private/` are automatically ignored by git
- Backup these files securely and separately from the repository
- Consider encrypting sensitive files before storing them

## 📦 Package Management Structure

The package installation system is organized by package manager for maximum clarity:

### Official Repositories (`pacman/`)
- **base.txt**: Essential system packages (sudo, git, vim, etc.)
- **development.txt**: Development tools from official repos (gcc, python, nodejs, etc.)
- **desktop.txt**: Desktop environment packages (gnome, firefox, etc.)
- **optional.txt**: Additional software from official repositories

### Arch User Repository (`aur/`)
- **base.txt**: Essential packages from AUR (yay, base-devel extensions, etc.)
- **development.txt**: Development tools from AUR (visual-studio-code-bin, etc.)
- **desktop.txt**: Desktop applications from AUR (discord, spotify, etc.)
- **optional.txt**: Optional AUR packages (games, specialized tools, etc.)

This structure ensures:
- **Clear separation** between official and AUR packages
- **Efficient installation** (batch install per package manager)
- **Easy maintenance** and customization
- **No ambiguity** about which package manager to use

### Package List Format
Each package file uses a standardized format for easy parsing:
```bash
# Comments start with #
# Package entries start with - followed by package name
- package_name
- another_package
```

Example from `aur/development.txt`:
```bash
# Conventional Commits Tool
# Python tool for creating conventional commits
# https://github.com/commitizen-tools/commitizen
- python-commitizen
```

## 📂 Dotfiles Management

The dotfiles deployment system uses **GNU Stow** for automatic symlink management:

### Files Managed:

#### User Configuration Files:
- **`.bashrc`**: Complete Bash configuration with environment variables ✅
- **`.gitconfig`**: Git configuration with PGP signing ✅
- **`.sshd_config`**: Hardened SSH server configuration ✅
- **`.gnupg/`**: Complete GnuPG configuration directory ✅

#### System Configuration Files:
- **`etc/timeshift/timeshift.json`**: Timeshift backup system configuration ✅

### Deployment Process (`scripts/04-dotfiles.sh`):

#### Features:
- **Dual Deployment**: Separate handling of user and system configuration files
- **GNU Stow Integration**: Automatic symlink creation and management
- **Safe Deployment**: Removes existing conflicting files before deployment
- **System Backup**: Automatic backup of existing system files before replacement
- **Sudo Integration**: Handles system files that require root privileges
- **Permission Management**: Sets appropriate permissions for sensitive files
- **Configuration Reload**: Automatically reloads Bash and GPG agent
- **Verification**: Confirms all symlinks were created successfully

#### Security Features:
- **Selective Removal**: Only removes specific conflicting files (not wildcards)
- **Interactive Confirmation**: Asks before making changes
- **System File Backup**: Creates timestamped backups in `/tmp` before system changes
- **Proper Permissions**: Sets 700/600 for GnuPG, 644 for configs, root:root for system files
- **Path Validation**: Verifies all directories exist before proceeding
- **Sudo Verification**: Checks for proper privileges before attempting system changes

#### Usage:
```bash
# Run dotfiles deployment directly
./scripts/04-dotfiles.sh

# Or as part of post-installation setup
./setup post-install
```

#### What It Does:
1. **Verifies Prerequisites**: Checks GNU Stow installation, directories, and sudo privileges
2. **Removes Conflicts**: Safely removes existing files that would conflict with stow
3. **Creates User Symlinks**: Uses `stow --target=/home/cristian --ignore=etc dotfiles`
4. **Creates System Symlinks**: Uses `sudo stow --target=/etc dotfiles/etc` (with backup)
5. **Sets Permissions**: Configures proper file permissions for both user and system files
6. **Reloads Configurations**: Updates Bash environment and GPG agent
7. **Verifies Deployment**: Confirms all symlinks were created successfully

#### File Mapping:

**User Files:**
```
dotfiles/.bashrc      → /home/cristian/.bashrc
dotfiles/.gitconfig   → /home/cristian/.gitconfig  
dotfiles/.sshd_config → /home/cristian/.sshd_config
dotfiles/.gnupg/      → /home/cristian/.gnupg/
```

**System Files:**
```
dotfiles/etc/timeshift/timeshift.json → /etc/timeshift/timeshift.json
```

### Requirements:
- **GNU Stow**: Must be installed (`pacman -S stow`)
- **Project Location**: `/home/cristian/development/projects/arch-linux-dotfiles/`
- **Write Permissions**: User must have write access to home directory
- **Sudo Privileges**: Required for system file deployment (optional, can skip with warning)

### System Files Configuration:

#### Timeshift Backup Configuration:
The `dotfiles/etc/timeshift/timeshift.json` provides a comprehensive backup strategy:

**Features:**
- **Monthly Snapshots**: Automated monthly backups (keeps 2)
- **Smart Exclusions**: Excludes cache, temporary, and system directories
- **BTRFS Ready**: Compatible with both ext4 and BTRFS filesystems
- **Email Control**: Prevents spam from cron backup notifications

**Key Exclusions:**
```
/home/*/.cache/**         # User cache directories
/home/*/.thumbnails/**    # Image thumbnails
/home/*/Downloads/**      # Download directories
/var/cache/**             # System cache
/var/log/**              # System logs  
/tmp/** and /var/tmp/**  # Temporary files
```

**Installation:**
The configuration is automatically deployed to `/etc/timeshift/timeshift.json` with proper root permissions when running the dotfiles script with sudo privileges.

## ⚙️ System Services Configuration

The system services configuration script manages essential system services:

### Services Configured (`scripts/05-services.sh`):

#### Docker Service:
- **Start and enable** Docker daemon
- **Add user** to docker group for non-root access
- **Activate group** membership immediately when possible
- **Container management** without sudo privileges

#### SSH Service:
- **Start and enable** SSH daemon (sshd)
- **Secure configuration** using hardened .sshd_config
- **Custom port** 2222 for enhanced security
- **Key-based authentication** only

#### CUPS Service:
- **Start and enable** printing system
- **Printer management** and sharing capabilities
- **Network printer** support

### Features:
- **Interactive confirmation** before making changes
- **Comprehensive logging** of all operations
- **Error handling** with rollback capabilities
- **Service verification** after configuration
- **Group membership** management for Docker

### Usage:
```bash
# Run services configuration directly
./scripts/05-services.sh

# Or as part of post-installation setup
./setup post-install
```

### What It Does:
1. **Configure Docker**: Start service, enable autostart, add user to docker group
2. **Configure SSH**: Start sshd with secure configuration from dotfiles
3. **Configure CUPS**: Enable printing system for local and network printers
4. **Verify Services**: Check that all services are running correctly
5. **User Notification**: Inform about logout/login requirement for Docker group

### Post-Configuration Notes:
- **Docker group**: You may need to logout/login for Docker group changes to take effect
- **SSH access**: Available on custom port 2222 as configured in .sshd_config  
- **Printing**: CUPS web interface available at http://localhost:631

## 🔧 Available Commands

```bash
./setup pre-install    # Run my pre-installation setup
./setup post-install   # Run my post-installation setup
./setup full           # Run my complete setup process
./setup --help         # Show help information
./setup --version      # Show version information
```

## 🎯 Development Roadmap

### Completed ✅
- [x] Project structure
- [x] Network detection and WiFi setup automation
- [x] Utility functions (logging, colors, helpers)
- [x] Main setup script with argument handling
- [x] Package management structure (pacman/AUR)
- [x] Archinstall configuration integration
- [x] Automated installation process

### To Do 📋
- [x] Initial system backup (01-initial-backup.sh)
- [x] Post-installation system configuration (02-post-install.sh)
- [x] Package installation scripts (03-packages.sh)
- [x] Dotfiles management (04-dotfiles.sh)
- [x] Service configuration (05-services.sh)
- [ ] User environment setup

## 🤝 Contributing

1. Create your feature branch
2. Follow the existing code structure and conventions
3. Use **Conventional Commits** for all commit messages:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `refactor:` for code refactoring
   - `test:` for adding tests
   - `chore:` for maintenance tasks
4. Test your changes thoroughly
5. Submit a pull request with a clear description

### Commit Message Examples
```bash
feat: add new package installation script
fix: resolve WiFi connection timeout issue
docs: update installation instructions
refactor: improve network detection logic
```

## 📝 Notes

- The script **automatically detects ethernet connections** and prioritizes them over WiFi
- WiFi configuration (`config/setup_passwords.env`) is **only required** when no ethernet connection is available  
- The pre-install script **automatically runs archinstall** with the provided configurations
- **⚠️ Warning**: The installation will format disks according to `archinstall_config.json`
- I run `./setup pre-install` from the Arch Linux live USB environment
- I run `./setup post-install` from the installed Arch Linux system
- My system uses modular scripts for easy maintenance and customization

## 🔒 Security

### SSH Configuration

I've included a hardened SSH server configuration for secure remote access:

#### Files Included:
- **`dotfiles/.sshd_config`**: Secure SSH server configuration for Arch Linux ✅

#### Security Features Implemented:
- **No Root Login**: Root access via SSH completely disabled
- **SSH Key Authentication Only**: Password authentication disabled
- **Custom Port**: Uses port 2222 instead of default 22
- **Modern Cryptography**: Only secure algorithms allowed
- **Connection Limits**: Rate limiting and timeout protection
- **User Access Control**: Only specific users allowed
- **Comprehensive Logging**: Detailed audit logging enabled
- **Forwarding Disabled**: X11 and TCP forwarding blocked

#### Installation Instructions:
```bash
# Copy SSH configuration files
sudo cp dotfiles/.sshd_config /etc/ssh/sshd_config

# Set proper permissions
sudo chmod 644 /etc/ssh/sshd_config

# Test configuration before applying
sudo sshd -t

# Apply configuration
sudo systemctl restart sshd
sudo systemctl enable sshd

# Generate SSH keys if needed
ssh-keygen -t ed25519 -C "your_email@example.com"
```

#### Important Notes:
- Replace 'cristian' in `AllowUsers` with your actual username
- Change the port number (2222) to your preferred custom port
- Ensure you have SSH keys set up before disabling password authentication
- Test the configuration from another terminal before closing your current session

### Bash Shell Configuration

I've included a comprehensive Bash configuration for optimal shell experience:

#### Files Included:
- **`dotfiles/.bashrc`**: Complete Bash configuration with documented sections ✅

#### Features Implemented:
- **Environment Variables**: Centralized section for all environment variable definitions
- **GnuPG Integration**: `GNUPGHOME` points to dotfiles GnuPG configuration
- **Enhanced History**: Large history size with duplicate removal
- **Colored Output**: Smart color detection for ls, grep, and other commands
- **Safety Aliases**: Interactive confirmation for rm, cp, mv operations
- **Completion Support**: Bash completion for better command-line experience
- **Custom Prompt**: User@host:path format with colors

#### Key Environment Variables:
- **`GNUPGHOME`**: `$HOME/.gnupg` (standard GnuPG directory)
- **`EDITOR`**: `vim` (default editor for git commits, etc.)
- **`HISTSIZE`**: 10,000 commands in memory
- **`HISTFILESIZE`**: 20,000 commands in history file

#### Sections Overview:
1. **Environment Variables**: All environment variable definitions
2. **Shell Options**: Bash behavior and history settings
3. **Aliases**: Command shortcuts and safety aliases
4. **Completion**: Programmable completion features
5. **Prompt Configuration**: Custom PS1 prompt styling

### GnuPG Configuration

I've included a comprehensive GnuPG configuration for secure encryption, signing, and key management:

#### Files Included:
- **`dotfiles/.gnupg/gpg.conf`**: Main GnuPG configuration with security hardening ✅
- **`dotfiles/.gnupg/gpg-agent.conf`**: GPG agent configuration for key caching ✅
- **`dotfiles/.gitconfig`**: Enhanced Git configuration with PGP signing ✅

#### Security Features Implemented:
- **Automatic Commit Signing**: All commits and tags signed with PGP key
- **Strong Cryptographic Preferences**: AES-256, SHA-512, secure algorithms only
- **Enhanced Key Display**: Long key IDs and fingerprints for better verification
- **Secure Caching**: 30-minute default cache with 2-hour maximum
- **Hardened Defaults**: Disabled weak algorithms and improved security settings
- **Cross-Certification**: Required for subkeys to prevent attacks
- **UTF-8 Support**: Proper international character handling

#### Key Information:
- **Key ID**: `FC2047CC47F04C1E`
- **User**: Cristian Palau <cp@cristianpalau.com>
- **Algorithm**: RSA 4096-bit
- **Expiration**: No expiration

#### Installation Instructions:
```bash
# Install GnuPG configuration files
ln -sf "$(pwd)/dotfiles/.gnupg/gpg.conf" ~/.gnupg/gpg.conf
ln -sf "$(pwd)/dotfiles/.gnupg/gpg-agent.conf" ~/.gnupg/gpg-agent.conf
ln -sf "$(pwd)/dotfiles/.gitconfig" ~/.gitconfig

# Set proper permissions
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/gpg.conf ~/.gnupg/gpg-agent.conf

# Restart GPG agent to apply changes
gpgconf --kill gpg-agent
gpg-agent --daemon

# Verify configuration
gpg --list-secret-keys --keyid-format LONG
git config --get user.signingkey

# Test signing functionality
echo "test message" | gpg --clearsign
git log --show-signature -1
```

#### Important Notes:
- The configuration uses key ID `FC2047CC47F04C1E` - replace with your actual key ID
- Email synchronized between Git and GnuPG: `cp@cristianpalau.com`
- Pinentry set to GTK2 - adjust for your desktop environment (Qt, CLI, etc.)
- All commits and tags will be automatically signed when configuration is active
- Backup your private keys securely before using this configuration

#### Environment Variables (Optional):
```bash
# Add to your shell profile (~/.bashrc, ~/.zshrc) if using SSH support:
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
```

### General Security Practices

- My WiFi credentials are stored locally and never transmitted
- Temporary password files are automatically cleaned up
- All my scripts include error handling and validation

---

**Version**: 1.0.0  
**License**: MIT  
**Author**: Cristian Palau