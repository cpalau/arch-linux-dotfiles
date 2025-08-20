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
│   ├── 01-post-install.sh         # My post-installation configuration (to be created)
│   ├── 02-packages.sh             # My package installation (to be created)
│   ├── 03-dotfiles.sh             # My dotfiles deployment (to be created)
│   ├── 04-services.sh             # My system services setup (to be created)
│   └── utils/
│       ├── colors.sh              # My color definitions ✅
│       ├── logging.sh             # My logging functions ✅
│       └── helpers.sh             # My common helper functions ✅
├── dotfiles/
│   ├── .bashrc                    # My bash configuration (to be created)
│   ├── .vimrc                     # My vim configuration (to be created)
│   ├── .gitconfig                 # My git configuration ✅
│   └── .config/                   # My application configurations (to be created)
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
- [ ] Post-installation system configuration
- [ ] Package installation scripts (02-packages.sh)
- [ ] Dotfiles management (03-dotfiles.sh)
- [ ] Service configuration (04-services.sh)
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

- My WiFi credentials are stored locally and never transmitted
- Temporary password files are automatically cleaned up
- All my scripts include error handling and validation

---

**Version**: 1.0.0  
**License**: MIT  
**Author**: Cristian Palau